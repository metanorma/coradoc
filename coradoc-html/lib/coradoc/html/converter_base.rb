# frozen_string_literal: true

module Coradoc
  module Html
    # Abstract base class for HTML output converters
    #
    # This class defines the interface that all HTML output converters must implement.
    # It provides common functionality for document validation, configuration building,
    # and HTML output generation.
    #
    # @abstract Subclass and implement {#convert} to create a custom converter
    #
    # @example Creating a custom converter
    #   class MyConverter < Coradoc::Html::ConverterBase
    #     def convert
    #       # Generate HTML from document
    #     end
    #   end
    class ConverterBase
      # Error class for converter validation errors
      class ValidationError < Coradoc::Error; end

      # Error class for unsupported document types
      class UnsupportedDocumentError < Coradoc::Error; end

      # Base class for output converter configurations.
      #
      # Provides shared `merge` and `defaults` patterns.
      # Subclasses define `initialize`, `to_h`, and `validate!`.
      class ConfigurationBase
        class << self
          # Declare a configuration attribute with an optional default.
          # Replaces manual attr_accessor + initialize + to_h boilerplate.
          def attribute(name, default: nil)
            attr_accessor name

            configuration_attributes[name] = default
          end

          # Registry of declared attributes and their defaults
          def configuration_attributes
            @configuration_attributes ||= {}
          end

          def defaults
            new
          end
        end

        def initialize(**options)
          self.class.configuration_attributes.each do |name, default|
            value = options.fetch(name) { default.is_a?(Proc) ? default.call : default }
            public_send(:"#{name}=", value)
          end
        end

        def to_h
          self.class.configuration_attributes.each_with_object({}) do |(name, _), hash|
            hash[name] = public_send(name)
          end
        end

        def merge(other)
          other_hash = other.is_a?(self.class) ? other.to_h : other.to_h.transform_keys(&:to_sym)
          self.class.new(**to_h, **other_hash)
        end

        protected

        def range_check(name, min, max, label: nil)
          value = public_send(name)
          return if value.is_a?(Integer) && value.between?(min, max)

          display = label || name.to_s.tr('_', ' ').gsub(/\b\w/, &:upcase)
          raise ConverterBase::ValidationError,
                "#{display} must be an integer between #{min} and #{max}"
        end
      end

      attr_reader :document, :config

      # Initialize a new converter instance
      #
      # @param document [Coradoc::CoreModel::StructuralElement] The document to convert
      # @param config [Hash, Configuration] Converter configuration
      # @raise [UnsupportedDocumentError] if document is not a valid type
      def initialize(document, config = {})
        @document = validate_input(document)
        @config = build_config(config)
      end

      # Convert the document to HTML
      #
      # @abstract Subclasses must implement this method
      # @return [String] HTML output
      # @raise [NotImplementedError] if not implemented by subclass
      def convert
        raise NotImplementedError,
              "#{self.class.name} must implement #convert method"
      end

      # Convert and write to file
      #
      # @param output_path [String] Path to write the output file
      # @return [String] The output path
      def to_file(output_path)
        html = convert

        # Ensure parent directory exists
        output_dir = File.dirname(output_path)
        FileUtils.mkdir_p(output_dir) unless output_dir == '.'

        File.write(output_path, html)

        output_path
      end

      # Class method to convert a document
      #
      # @param document [Coradoc::CoreModel::StructuralElement] The document to convert
      # @param config [Hash] Converter configuration
      # @return [String] HTML output
      def self.convert(document, config = {})
        new(document, config).convert
      end

      # Class method to convert and write to file
      #
      # @param document [Coradoc::CoreModel::StructuralElement] The document to convert
      # @param output_path [String] Path to write the output file
      # @param config [Hash] Converter configuration
      # @return [String] The output path
      def self.to_file(document, output_path, config = {})
        new(document, config).to_file(output_path)
      end

      protected

      def validate_input(document)
        # Handle transformer hash output
        document = Coradoc::Transformer.transform(document) if document.is_a?(Hash) && document.key?(:document)

        # Validate document type - ONLY accept CoreModel types
        unless document.is_a?(Coradoc::CoreModel::Base)
          raise UnsupportedDocumentError,
                "Expected CoreModel document, got: #{document.class}. " \
                'Transform your document to CoreModel first using the appropriate ' \
                'format transformer (e.g., ToCoreModel for your source format).'
        end

        document
      end

      def build_config(config)
        klass = configuration_class
        return config unless klass

        case config
        when klass
          config.validate!
          config
        when Hash
          klass.new(**config)
        else
          klass.defaults
        end
      end

      def configuration_class
        nil
      end
    end
  end
end
