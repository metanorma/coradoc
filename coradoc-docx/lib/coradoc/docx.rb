# frozen_string_literal: true

require 'coradoc'
require 'coradoc/core_model'
require 'uniword'

# Coradoc::Docx provides DOCX (OOXML) format support for Coradoc.
#
# Transforms Uniword::Wordprocessingml model trees into
# Coradoc::CoreModel, enabling DOCX → AsciiDoc and DOCX → Markdown
# conversion via the hub-and-spoke architecture.
#
# @example Convert DOCX to AsciiDoc
#   Coradoc.convert("input.docx", from: :docx, to: :asciidoc)
#
# @example Parse DOCX to CoreModel
#   core = Coradoc::Docx.parse_to_core("input.docx")
#
module Coradoc
  module Docx
    autoload :VERSION, 'coradoc/docx/version'
    autoload :Transform, 'coradoc/docx/transform'

    class << self
      # Parse a DOCX input to CoreModel
      #
      # @param input [String, IO, Uniword::Wordprocessingml::DocumentRoot]
      #   Path to .docx file, IO stream, or pre-parsed Uniword document
      # @param _options [Hash] additional options (reserved)
      # @return [Coradoc::CoreModel::StructuralElement] CoreModel document
      def parse_to_core(input, _options = {})
        document = coerce_to_document(input)
        Transform::ToCoreModel.transform(document)
      end

      # Parse a DOCX input to Uniword model (no CoreModel conversion)
      #
      # @param input [String, IO] path to .docx file or IO stream
      # @return [Uniword::Wordprocessingml::DocumentRoot] Uniword document model
      def parse(input, _options = {})
        coerce_to_document(input)
      end

      # Whether this format supports serialization
      def serialize?
        true
      end

      # Serialize CoreModel to DOCX
      #
      # @param core_model [Coradoc::CoreModel::Base] CoreModel document
      # @param options [Hash] serialization options
      # @option options [String] :output_path Path to write .docx file
      # @return [String, Uniword::Wordprocessingml::DocumentRoot]
      #   Returns the output path if :output_path given, otherwise the DocumentRoot
      def serialize(core_model, **options)
        document = Transform::FromCoreModel.transform(core_model)

        if options[:output_path]
          document.save(options[:output_path])
          options[:output_path]
        elsif options[:to_io]
          io = options[:to_io]
          document.save(io.path)
          io
        else
          document
        end
      end

      private

      def coerce_to_document(input)
        case input
        when Uniword::Wordprocessingml::DocumentRoot
          input
        when String
          raise ArgumentError, "File not found: #{input}" unless File.exist?(input)

          Uniword::DocumentFactory.from_file(input)

        when IO, StringIO
          Uniword::DocumentFactory.from_io(input)
        else
          raise ArgumentError,
                "Expected file path, IO, or DocumentRoot, got #{input.class}"
        end
      end
    end
  end
end

# Auto-register :docx format with Coradoc when both gems are loaded
Coradoc.register_format(:docx, Coradoc::Docx) unless Coradoc.registered_formats.include?(:docx)
