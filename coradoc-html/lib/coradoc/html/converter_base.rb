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

      # Get the converter name
      #
      # @return [Symbol] Converter name (e.g., :static, :spa)
      def converter_name
        @converter_name ||= self.class.name.split('::').last
                                .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                                .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                                .downcase
                                .to_sym
      end

      protected

      # Validate the input document
      #
      # @param document [Object] The document to validate
      # @return [Coradoc::CoreModel::Base] The validated document
      # @raise [UnsupportedDocumentError] if document is not valid
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

      # Build configuration from options
      #
      # @param config [Hash, Object] Configuration options or object
      # @return [Object] Built configuration object
      def build_config(config)
        # If config is already a Configuration object, validate and return it
        if config.respond_to?(:validate!)
          config.validate! if config.respond_to?(:validate!)
          return config
        end

        # Otherwise, build from hash (subclasses should override this)
        config
      end

      # Extract document title
      #
      # @return [String] Document title
      def extract_document_title
        # Handle CoreModel::StructuralElement (has title directly)
        if @document.respond_to?(:title) && @document.title
          title = @document.title
          return title if title.is_a?(String)
          return title.text if title.respond_to?(:text)

          return title.to_s
        end

        'Untitled Document'
      end

      # Extract text from content (array of inline elements)
      #
      # @param content [Array] Content elements
      # @return [String] Extracted text
      def extract_text_from_content(content)
        case content
        when Array
          content.map { |item| extract_text_from_content(item) }.join
        when String
          content
        when Coradoc::CoreModel::InlineElement
          content.content.to_s
        when Coradoc::CoreModel::Base
          if content.respond_to?(:content)
            extract_text_from_content(content.content)
          else
            content.to_s
          end
        else
          content.to_s
        end
      end

      # Escape HTML content
      #
      # @param text [String] Text to escape
      # @return [String] Escaped text
      def escape_html(text)
        Coradoc::Html::Base.escape_html(text.to_s)
      end

      # Escape HTML attribute value
      #
      # @param value [String] Value to escape
      # @return [String] Escaped value
      def escape_attr(value)
        value.to_s.gsub('"', '&quot;').gsub('<', '&lt;').gsub('>', '&gt;')
      end
    end
  end
end
