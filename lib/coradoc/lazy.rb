# frozen_string_literal: true

module Coradoc
  # Lazy evaluation support for large document processing.
  #
  # This module provides lazy enumeration and on-demand processing
  # capabilities for handling large documents without loading everything
  # into memory at once.
  #
  # @example Lazy section iteration
  #   document = Coradoc.parse(large_document, format: :asciidoc)
  #   lazy_doc = Coradoc::Lazy::DocumentWrapper.new(document)
  #
  #   lazy_doc.each_section do |section|
  #     process_section(section)
  #   end
  #
  # @example Lazy transformation
  #   lazy_result = Coradoc::Lazy.transform(document) do |section|
  #     transform_section(section)
  #   end
  #   lazy_result.to_a  # Process all sections
  #
  module Lazy
    # Wrapper for lazy document iteration
    class DocumentWrapper
      include Enumerable

      # @return [Object] The wrapped document
      attr_reader :document

      # Create a lazy document wrapper
      #
      # @param document [Object] Document to wrap
      # @param options [Hash] Configuration options
      # @option options [Integer] :batch_size Number of items per batch (default: 10)
      # @option options [Boolean] :cache_processed Whether to cache processed items
      def initialize(document, options = {})
        @document = document
        @batch_size = options[:batch_size] || 10
        @cache_processed = options.fetch(:cache_processed, true)
        @cache = {}
      end

      # Iterate over sections lazily
      #
      # @yield [Object] Each section
      # @return [Enumerator] If no block given
      def each_section(&block)
        return enum_for(:each_section) unless block_given?

        sections = extract_sections
        if sections.respond_to?(:lazy)
          sections.lazy.each(&block)
        else
          sections.each(&block)
        end
      end

      # Iterate over children lazily
      #
      # @yield [Object] Each child element
      # @return [Enumerator] If no block given
      def each_child(&block)
        return enum_for(:each_child) unless block_given?

        children = extract_children
        if children.respond_to?(:lazy)
          children.lazy.each(&block)
        else
          children.each(&block)
        end
      end

      # Get a section by index without loading all sections
      #
      # @param index [Integer] Section index
      # @return [Object, nil] Section at index or nil
      def section_at(index)
        return nil if index.nil? || index.negative?

        sections = extract_sections
        if sections.is_a?(Array)
          sections[index]
        elsif sections.respond_to?(:drop)
          sections.drop(index).first
        else
          sections.to_a[index]
        end
      end

      # Get the first N sections without loading all
      #
      # @param n [Integer] Number of sections
      # @return [Array<Object>] First N sections
      def first_sections(n = 1)
        sections = extract_sections
        if sections.respond_to?(:take)
          sections.take(n).to_a
        else
          sections.first(n)
        end
      end

      # Process sections in batches
      #
      # @param batch_size [Integer] Override default batch size
      # @yield [Array<Object>] Batch of sections
      # @return [Enumerator] If no block given
      def each_batch(batch_size = nil)
        return enum_for(:each_batch, batch_size) unless block_given?

        size = batch_size || @batch_size
        sections = extract_sections

        batch = []
        sections.each do |section|
          batch << section
          if batch.size >= size
            yield batch
            batch = []
          end
        end
        yield batch unless batch.empty?
      end

      # Get total section count (may force evaluation)
      #
      # @return [Integer] Number of sections
      def section_count
        sections = extract_sections
        if sections.respond_to?(:count) && !sections.is_a?(Enumerator)
          sections.count
        else
          sections.to_a.size
        end
      end

      # Alias for each_section
      alias each each_section

      private

      # Extract sections from document
      #
      # @return [Enumerable] Sections enumerable
      def extract_sections
        case @document
        when Coradoc::CoreModel::StructuralElement
          extract_sections_from_structural(@document)
        when ->(d) { d.respond_to?(:sections) }
          @document.sections || []
        when ->(d) { d.respond_to?(:children) }
          extract_sections_from_children(@document.children)
        else
          []
        end
      end

      # Extract sections from CoreModel structural element
      def extract_sections_from_structural(element)
        return [] unless element.respond_to?(:children)

        element.children.lazy.select do |child|
          child.is_a?(Coradoc::CoreModel::StructuralElement) &&
            child.element_type == 'section'
        end
      end

      # Extract sections from children array
      def extract_sections_from_children(children)
        return [] unless children

        children.lazy.select do |child|
          section_like?(child)
        end
      end

      # Check if element is section-like
      def section_like?(element)
        case element
        when Coradoc::CoreModel::StructuralElement
          element.element_type == 'section'
        else
          element.class.name&.include?('Section')
        end
      end

      # Extract all children
      def extract_children
        case @document
        when Coradoc::CoreModel::StructuralElement
          @document.children || []
        when ->(d) { d.respond_to?(:children) }
          @document.children || []
        else
          []
        end
      end
    end

    # Lazy transformation pipeline
    class TransformationPipeline
      # Create a lazy transformation pipeline
      #
      # @param source [Enumerable] Source enumerable
      # @param transformers [Array<Proc>] Transformer functions
      def initialize(source, transformers = [])
        @source = source
        @transformers = transformers
      end

      # Add a transformation step
      #
      # @yield [Object] Element to transform
      # @return [TransformationPipeline] New pipeline with transformation
      def map(&block)
        self.class.new(@source, @transformers + [[:map, block]])
      end

      # Add a filter step
      #
      # @yield [Object] Element to filter
      # @return [TransformationPipeline] New pipeline with filter
      def select(&block)
        self.class.new(@source, @transformers + [[:select, block]])
      end

      # Add a rejection step
      #
      # @yield [Object] Element to reject
      # @return [TransformationPipeline] New pipeline with rejection
      def reject(&block)
        self.class.new(@source, @transformers + [[:reject, block]])
      end

      # Add a flat map step
      #
      # @yield [Object] Element to flat map
      # @return [TransformationPipeline] New pipeline with flat map
      def flat_map(&block)
        self.class.new(@source, @transformers + [[:flat_map, block]])
      end

      # Take first N elements
      #
      # @param n [Integer] Number of elements
      # @return [TransformationPipeline] New pipeline with take
      def take(n)
        self.class.new(@source, @transformers + [[:take, n]])
      end

      # Drop first N elements
      #
      # @param n [Integer] Number of elements
      # @return [TransformationPipeline] New pipeline with drop
      def drop(n)
        self.class.new(@source, @transformers + [[:drop, n]])
      end

      # Execute pipeline and get results
      #
      # @return [Array] Transformed results
      def to_a
        build_enumerator.to_a
      end

      # Execute pipeline lazily
      #
      # @return [Enumerator::Lazy] Lazy enumerator
      def to_enum
        build_enumerator
      end

      # Iterate over results
      #
      # @yield [Object] Each result
      # @return [Enumerator] If no block given
      def each(&block)
        return to_enum unless block_given?

        build_enumerator.each(&block)
      end

      # Get first result
      #
      # @return [Object, nil] First result or nil
      def first
        build_enumerator.first
      end

      # Count results (forces evaluation)
      #
      # @return [Integer] Number of results
      def count(&block)
        if block
          build_enumerator.count(&block)
        else
          build_enumerator.count
        end
      end

      # Force evaluation of all elements
      #
      # @return [Array] All results
      def force
        to_a
      end

      private

      # Build the lazy enumerator with all transformations
      def build_enumerator
        enum = @source.respond_to?(:lazy) ? @source.lazy : @source.to_enum.lazy

        @transformers.reduce(enum) do |current, (type, arg)|
          apply_transformation(current, type, arg)
        end
      end

      # Apply a single transformation
      def apply_transformation(enum, type, arg)
        case type
        when :map
          enum.map(&arg)
        when :select
          enum.select(&arg)
        when :reject
          enum.reject(&arg)
        when :flat_map
          enum.flat_map(&arg)
        when :take
          enum.take(arg)
        when :drop
          enum.drop(arg)
        else
          enum
        end
      end
    end

    # Lazy reference resolver for includes and images
    class ReferenceResolver
      # Create a lazy reference resolver
      #
      # @param document [Object] Document with references
      # @param loader [Proc, nil] Custom loader for references
      def initialize(document, loader: nil)
        @document = document
        @loader = loader || method(:default_loader)
        @resolved = {}
      end

      # Resolve a reference lazily
      #
      # @param ref [String] Reference identifier
      # @return [Object, nil] Resolved content or nil
      def resolve(ref)
        return @resolved[ref] if @resolved.key?(ref)

        @resolved[ref] = @loader.call(ref, @document)
      end

      # Check if reference exists
      #
      # @param ref [String] Reference identifier
      # @return [Boolean] True if resolvable
      def resolvable?(ref)
        !resolve(ref).nil?
      end

      # Clear resolved cache
      #
      # @return [void]
      def clear_cache
        @resolved.clear
      end

      # Get cache statistics
      #
      # @return [Hash] Cache stats
      def cache_stats
        {
          cached_count: @resolved.size,
          cached_refs: @resolved.keys
        }
      end

      private

      # Default loader for references
      def default_loader(_ref, _document)
        # Try to find in document's anchor/index
        nil
      end
    end

    # Lazy chunk processor for streaming large content
    class ChunkProcessor
      # Create a lazy chunk processor
      #
      # @param chunk_size [Integer] Size of each chunk in bytes
      # 1MB default
      def initialize(chunk_size: 1024 * 1024)
        @chunk_size = chunk_size
      end

      # Process content in chunks
      #
      # @param content [String, IO] Content to process
      # @yield [String, Integer] Chunk content and chunk index
      # @return [Enumerator] If no block given
      def process(content, &block)
        return enum_for(:process, content) unless block_given?

        if content.is_a?(IO) || content.respond_to?(:read)
          process_io(content, &block)
        else
          process_string(content.to_s, &block)
        end
      end

      private

      # Process IO stream in chunks
      def process_io(io)
        index = 0
        loop do
          chunk = io.read(@chunk_size)
          break if chunk.nil? || chunk.empty?

          yield chunk, index
          index += 1
        end
      end

      # Process string in chunks
      def process_string(str)
        index = 0
        offset = 0

        while offset < str.length
          chunk = str[offset, @chunk_size]
          yield chunk, index
          offset += @chunk_size
          index += 1
        end
      end
    end

    class << self
      # Create a lazy document wrapper
      #
      # @param document [Object] Document to wrap
      # @param options [Hash] Configuration options
      # @return [DocumentWrapper] Wrapped document
      def wrap(document, options = {})
        DocumentWrapper.new(document, options)
      end

      # Create a lazy transformation pipeline
      #
      # @param source [Enumerable] Source elements
      # @yield Block for pipeline configuration
      # @return [TransformationPipeline] Configured pipeline
      def transform(source)
        pipeline = TransformationPipeline.new(source)
        if block_given?
          result = yield pipeline
          # Use block result if it's a TransformationPipeline, otherwise use original
          result.is_a?(TransformationPipeline) ? result : pipeline
        else
          pipeline
        end
      end

      # Create a lazy reference resolver
      #
      # @param document [Object] Document with references
      # @param loader [Proc, nil] Custom loader
      # @return [ReferenceResolver] Resolver instance
      def resolver(document, loader: nil)
        ReferenceResolver.new(document, loader: loader)
      end

      # Process large content in chunks
      #
      # @param content [String, IO] Content to process
      # @param chunk_size [Integer] Chunk size in bytes
      # @yield [String, Integer] Chunk and index
      # @return [Enumerator] If no block given
      def each_chunk(content, chunk_size: 1024 * 1024, &block)
        processor = ChunkProcessor.new(chunk_size: chunk_size)
        processor.process(content, &block)
      end

      # Create a lazy enumerator from array
      #
      # @param array [Array] Source array
      # @return [Enumerator::Lazy] Lazy enumerator
      def lazy_enum(array)
        return array.lazy if array.respond_to?(:lazy)

        array.to_enum.lazy
      end

      # Map and filter in a single lazy pass
      #
      # @param source [Enumerable] Source elements
      # @yield [Object] Element to transform (return nil to filter)
      # @return [Enumerator::Lazy] Lazy enumerator
      def filter_map(source, &block)
        lazy_enum(source).filter_map(&block)
      end
    end
  end
end
