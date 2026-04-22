# frozen_string_literal: true

module Coradoc
  # Streaming and chunked processing for large documents.
  #
  # This module provides utilities for processing large documents
  # without loading everything into memory. It supports chunked
  # parsing, streaming transformation, and incremental serialization.
  #
  # @example Streaming parsing
  #   Coradoc::Streaming.parse_large_file("large.adoc") do |section|
  #     process_section(section)
  #   end
  #
  # @example Chunked transformation
  #   Coradoc::Streaming.transform_in_chunks(document, chunk_size: 100) do |chunk|
  #     chunk.map { |element| transform_element(element) }
  #   end
  #
  # @example Incremental serialization
  #   File.open("output.html", "w") do |file|
  #     Coradoc::Streaming.serialize_incremental(document) do |chunk|
  #       file.write(chunk)
  #     end
  #   end
  #
  module Streaming
    # Configuration for streaming operations
    class Configuration
      # @return [Integer] Default chunk size
      attr_accessor :default_chunk_size

      # @return [Integer] Maximum memory usage (bytes)
      attr_accessor :max_memory

      # @return [Boolean] Enable memory monitoring
      attr_accessor :monitor_memory

      def initialize
        @default_chunk_size = 100
        @max_memory = 100 * 1024 * 1024 # 100MB
        @monitor_memory = true
      end
    end

    # Progress information for streaming operations
    class Progress
      attr_reader :total, :processed, :started_at, :errors

      def initialize(total: nil)
        @total = total
        @processed = 0
        @started_at = Time.now
        @errors = []
      end

      # Increment processed count
      #
      # @param count [Integer] Number of items processed
      # @return [Integer] New processed count
      def increment(count = 1)
        @processed += count
      end

      # Record an error
      #
      # @param error [String, Exception] The error
      # @return [void]
      def add_error(error)
        @errors << error
      end

      # Get elapsed time in seconds
      #
      # @return [Float]
      def elapsed
        Time.now - @started_at
      end

      # Get processing rate (items per second)
      #
      # @return [Float]
      def rate
        elapsed.positive? ? @processed / elapsed : 0
      end

      # Get estimated time remaining
      #
      # @return [Float, nil] Seconds remaining, or nil if total unknown
      def estimated_remaining
        return nil unless @total && rate.positive?

        (@total - @processed) / rate
      end

      # Get completion percentage
      #
      # @return [Float, nil] Percentage, or nil if total unknown
      def percentage
        return nil unless @total

        (@processed.to_f / @total * 100).round(1)
      end

      # Check if there are any errors
      #
      # @return [Boolean]
      def has_errors?
        @errors.any?
      end

      # Format as string
      #
      # @return [String]
      def to_s
        parts = ["#{@processed} processed"]
        parts << "of #{@total}" if @total
        parts << "(#{percentage}%)" if percentage
        parts << "at #{rate.round(1)}/sec"
        parts << "~#{(estimated_remaining / 60).round(1)}min remaining" if estimated_remaining
        parts.join(' ')
      end
    end

    # Chunk processor for batched operations
    class ChunkProcessor
      attr_reader :chunk_size, :progress

      # Create a chunk processor
      #
      # @param chunk_size [Integer] Number of items per chunk
      # @param total [Integer, nil] Total items to process
      def initialize(chunk_size: nil, total: nil)
        @chunk_size = chunk_size || configuration.default_chunk_size
        @progress = Progress.new(total: total)
        @current_chunk = []
      end

      # Process an item
      #
      # @param item [Object] Item to process
      # @yield Block to process chunk when full
      # @return [void]
      def process(item, &block)
        @current_chunk << item

        return unless @current_chunk.size >= @chunk_size

        flush(&block)
      end

      # Flush remaining items
      #
      # @yield Block to process remaining chunk
      # @return [void]
      def flush
        return if @current_chunk.empty?

        yield(@current_chunk) if block_given?
        @progress.increment(@current_chunk.size)
        @current_chunk = []
      end

      private

      def configuration
        Streaming.configuration
      end
    end

    # Memory monitor for streaming operations
    class MemoryMonitor
      # Get current memory usage
      #
      # @return [Integer] Memory usage in bytes
      def self.current_usage
        return 0 unless defined?(GC)

        GC.start
        GC.stat[:total_allocated_objects] * 8 # Rough estimate
      end

      # Check if memory usage exceeds limit
      #
      # @param limit [Integer] Memory limit in bytes
      # @return [Boolean]
      def self.exceeds_limit?(limit)
        current_usage > limit
      end

      # Get memory statistics
      #
      # @return [Hash]
      def self.stats
        return {} unless defined?(GC)

        GC.start
        GC.stat
      end
    end

    # Stream reader for large files
    class StreamReader
      # Stream read a file line by line
      #
      # @param path [String] File path
      # @param encoding [String] File encoding
      # @yield Block receives each line
      # @return [Progress] Reading progress
      def self.read_lines(path, encoding: 'UTF-8')
        progress = Progress.new

        File.foreach(path, encoding: encoding) do |line|
          yield(line) if block_given?
          progress.increment
        end

        progress
      end

      # Stream read a file in chunks of lines
      #
      # @param path [String] File path
      # @param chunk_size [Integer] Lines per chunk
      # @param encoding [String] File encoding
      # @yield Block receives chunk of lines
      # @return [Progress] Reading progress
      def self.read_chunks(path, chunk_size: 100, encoding: 'UTF-8')
        progress = Progress.new
        chunk = []

        File.foreach(path, encoding: encoding) do |line|
          chunk << line
          if chunk.size >= chunk_size
            yield(chunk) if block_given?
            progress.increment(chunk.size)
            chunk = []
          end
        end

        # Process remaining lines
        if chunk.any?
          yield(chunk) if block_given?
          progress.increment(chunk.size)
        end

        progress
      end
    end

    # Stream writer for incremental output
    class StreamWriter
      # Create a stream writer
      #
      # @param output [IO, StringIO] Output stream
      def initialize(output)
        @output = output
        @bytes_written = 0
      end

      # Write content to the stream
      #
      # @param content [String] Content to write
      # @return [Integer] Number of bytes written
      def write(content)
        bytes = @output.write(content.to_s)
        @bytes_written += bytes
        bytes
      end

      # Write a line to the stream
      #
      # @param line [String] Line to write
      # @return [Integer] Number of bytes written
      def write_line(line)
        write("#{line}\n")
      end

      # Flush the stream
      #
      # @return [void]
      def flush
        @output.flush if @output.respond_to?(:flush)
      end

      # Get total bytes written
      #
      # @return [Integer]
      attr_reader :bytes_written
    end

    # Module-level configuration
    class << self
      # Get streaming configuration
      #
      # @return [Configuration]
      def configuration
        @configuration ||= Configuration.new
      end

      # Configure streaming
      #
      # @yield Configuration block
      # @return [void]
      def configure
        yield(configuration) if block_given?
      end

      # Stream parse a large file
      #
      # @param path [String] File path
      # @param format [Symbol] Input format
      # @param chunk_size [Integer] Sections per chunk
      # @yield Block receives parsed chunks
      # @return [Progress] Parsing progress
      def parse_large_file(path, format: :asciidoc, chunk_size: nil)
        chunk_size ||= configuration.default_chunk_size
        progress = Progress.new

        # Read file content
        content = File.read(path)

        # Parse with format module
        format_module = Coradoc.get_format(format)
        raise UnsupportedFormatError, "Format '#{format}' is not registered" unless format_module

        if format_module.respond_to?(:parse_to_core)
          doc = format_module.parse_to_core(content)
        elsif format_module.respond_to?(:parse)
          doc = format_module.parse(content)
          doc = Coradoc.to_core(doc)
        end

        # Process sections in chunks
        if doc.respond_to?(:children)
          chunks = doc.children.each_slice(chunk_size).to_a
          chunks.each do |chunk|
            yield(chunk) if block_given?
            progress.increment(chunk.size)
          end
        else
          yield([doc]) if block_given?
          progress.increment
        end

        progress
      end

      # Transform elements in chunks
      #
      # @param elements [Array] Elements to transform
      # @param chunk_size [Integer] Elements per chunk
      # @yield Block receives and returns transformed chunks
      # @return [Array] All transformed elements
      def transform_in_chunks(elements, chunk_size: nil)
        chunk_size ||= configuration.default_chunk_size
        result = []

        elements.each_slice(chunk_size) do |chunk|
          transformed = block_given? ? yield(chunk) : chunk
          result.concat(transformed)
        end

        result
      end

      # Serialize document incrementally
      #
      # @param document [Object] Document to serialize
      # @param format [Symbol] Output format
      # @yield Block receives serialized chunks
      # @return [void]
      def serialize_incremental(document, format: :html)
        format_module = Coradoc.get_format(format)
        raise UnsupportedFormatError, "Format '#{format}' is not registered" unless format_module

        if format_module.respond_to?(:serialize)
          output = format_module.serialize(document)
          yield(output) if block_given?
        elsif format_module.respond_to?(:to_html)
          output = format_module.to_html(document)
          yield(output) if block_given?
        end
      end

      # Process a file with memory constraints
      #
      # @param path [String] Input file path
      # @param output_path [String] Output file path
      # @param format [Symbol] Input format
      # @param output_format [Symbol] Output format
      # @param max_memory [Integer] Maximum memory in bytes
      # @return [Progress] Processing progress
      def process_with_memory_limit(path, output_path, format: :asciidoc,
                                    output_format: :html, max_memory: nil)
        max_memory ||= configuration.max_memory
        progress = Progress.new

        File.open(output_path, 'w') do |output|
          writer = StreamWriter.new(output)

          parse_large_file(path, format: format, chunk_size: 50) do |chunk|
            GC.start if configuration.monitor_memory && MemoryMonitor.exceeds_limit?(max_memory)

            chunk.each do |element|
              serialize_incremental(element, format: output_format) do |html|
                writer.write(html)
              end
              progress.increment
            end
          end

          writer.flush
        end

        progress
      end
    end
  end
end
