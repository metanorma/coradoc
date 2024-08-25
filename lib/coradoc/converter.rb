require "fileutils"

module Coradoc
  class Converter
    attr_accessor :input, :output, :config

    def initialize(input = nil, output = nil, **config)
      @input = input || $stdin
      @output = output || $stdout

      @config = {
        input_options: {},
        output_options: {},
      }.merge(config)

      yield if block_given?
    end

    def self.call(*args, **kwargs, &block)
      new(*args, **kwargs, &block).convert
    end

    def input_processor
      if config[:input_processor]
        Input[config[:input_processor]]
      else
        Input.select_processor(input)
      end
    end

    def output_processor
      if config[:output_processor]
        Output[config[:output_processor]]
      else
        Output.select_processor(output)
      end
    end

    def convert(data = nil)
      input_id = input_processor.processor_id
      output_id = output_processor.processor_id

      unless data
        input = self.input
        input = File.open(input, "rb") if input.is_a? String
        data = input.read
        input_path = input.path if input.respond_to? :path
      end

      # Some input processors may prefer filenames
      if input_processor.respond_to? :processor_wants_filenames
        unless input.respond_to? :path
          raise NoInputPathError,
                "no input path given, but #{input_processor} wants that " +
                  "form. Ensure you don't read from standard input."
        end

        data = input.path
      end

      # We may need to configure destination path.
      output = self.output
      if output.is_a? String
        FileUtils.mkdir_p(File.dirname(output))
        output = File.open(output, "wb")
      end
      output_path = output.path if output.respond_to?(:path)

      input_options = config[:input_options]
      input_options = input_options.merge(destination: output_path) if output_path
      input_options = input_options.merge(sourcedir: File.dirname(input_path)) if input_path

      data = input_processor.processor_execute(data, input_options)

      # Two options are possible at this point:
      # Either we have a document we want to write to some output, or
      # we have a Hash, that contains a list of files and their
      # documents (where a nil key denotes the main file). Let's normalize
      # those cases.
      data = { nil => data } unless data.is_a? Hash

      # Let's check an edge case of non-nil keys and no output path
      if !output_path && data.keys.any? { |i| !i.nil? }
        raise NoOutputPathError,
              "no output path given, while wanting to write multiple files"
      end

      data = output_processor.processor_execute(data, config[:output_options])

      if input_processor.respond_to?(:processor_postprocess)
        data = input_processor.processor_postprocess(
          data, input_options.merge(output_processor: output_id)
        )
      end

      # Now we have all, let's write.
      data.each do |filename, content|
        if filename.nil?
          file = output
        else
          dirname = File.dirname(output_path)
          file = "#{dirname}/#{filename}"
          FileUtils.mkdir_p(File.dirname(file))
          file = File.open(file, "wb")
        end

        file.write(content)
        file.close
      end
    end

    class ConverterArgumentError < ArgumentError; end

    class NoInputPathError < ConverterArgumentError; end
    class NoOutputPathError < ConverterArgumentError; end
    class NoProcessorError < ConverterArgumentError; end

    module CommonInputOutputMethods
      def define(const)
        @processors[const.processor_id] = const
      end

      def [](id)
        @processors[id.to_sym]
      end

      def keys
        @processors.keys
      end

      def select_processor(filename)
        filename = filename.path if filename.respond_to? :path
        unless filename.is_a? String
          raise Converter::NoProcessorError,
                "Can't find a path for #{filename}. You must manually select the processor."
        end

        @processors.values.find do |i|
          i.processor_match?(filename)
        end or raise Converter::NoProcessorError,
                     "You must manually select the processor for #{filename}"
      end
    end
  end
end
