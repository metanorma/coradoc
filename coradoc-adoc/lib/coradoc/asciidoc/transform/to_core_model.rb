# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      class ToCoreModel
        include Coradoc::Transform::Base

        @registered = false

        class << self
          def register!
            return if @registered
            Transform::ToCoreModelRegistrations.register_all!
            @registered = true
          end

          def transform(model)
            register!
            return model.filter_map { |item| transform(item) } if model.is_a?(Array)
            return model unless model.is_a?(Coradoc::AsciiDoc::Model::Base)

            transformer = Registry.lookup(model.class)
            transformer ? transformer.call(model) : model
          end

          def extract_block_lines(block)
            non_break_lines = Array(block.lines).reject do |line|
              line.is_a?(Coradoc::AsciiDoc::Model::LineBreak) ||
                line.is_a?(Coradoc::AsciiDoc::Model::Break::PageBreak)
            end
            non_break_lines.map do |line|
              extract_text_content(line)
            end.join("\n")
          end

          def extract_title_text(title)
            return nil if title.nil?
            return title.to_s unless title.is_a?(Coradoc::AsciiDoc::Model::Title)

            content = title.content
            return '' if content.nil?

            if content.is_a?(String)
              content
            elsif content.is_a?(Array)
              content.map { |c| extract_text_content(c) }.join
            else
              extract_text_content(content)
            end
          end

          def extract_text_content(content)
            TextExtractVisitor.new.extract(content)
          end

          def extract_block_language(block)
            lang = block.lang
            return lang if lang.is_a?(String) && !lang.empty?

            attrs = block.attributes
            return nil unless attrs.is_a?(Coradoc::AsciiDoc::Model::AttributeList)

            named_lang = attrs['language']
            return named_lang.to_s if named_lang

            positional = attrs.positional
            positional[1]&.value&.to_s if positional.length > 1
          end

          def extract_document_attributes(doc)
            return nil unless doc.document_attributes

            metadata = Coradoc::CoreModel::Metadata.new
            doc.document_attributes.to_hash.each do |key, value|
              metadata[key.to_s] = value.to_s
            end
            metadata
          end

          def asciidoc_delimiter_to_semantic(delimiter)
            return :open if delimiter && delimiter.length < 4

            char = delimiter&.[](0)
            DelimiterMapping::CHAR_TO_SEMANTIC[char] || :open
          end

          def parse_inline_text(raw_text)
            return [] if raw_text.nil? || raw_text.to_s.strip.empty?

            text = raw_text.to_s
            parser = Coradoc::AsciiDoc::Parser::Base.new
            transformer = Coradoc::AsciiDoc::Transformer.new

            parsed = parser.text_any.parse(text)
            result = transformer.apply({ text: parsed })

            case result
            when Coradoc::AsciiDoc::Model::TextElement
              result.content.is_a?(Array) ? result.content : [result.content]
            when Array
              result
            when Coradoc::AsciiDoc::Model::Base
              [result]
            else
              [text]
            end
          rescue Parslet::ParseFailed
            [text]
          end

          def transform_inline_content(content)
            InlineTransformVisitor.new(self).transform(content)
          end

          def parse_and_transform_inline(text)
            return text if text.nil? || text.to_s.strip.empty?

            parsed_elements = Coradoc::AsciiDoc::Transformer.parse_inline_content(text)
            content_array = parsed_elements.flat_map do |element|
              element.is_a?(Coradoc::AsciiDoc::Model::TextElement) ? element.content : element
            end

            transformed = transform_inline_content(content_array)

            if transformed.all?(Coradoc::CoreModel::TextContent)
              transformed.map(&:text).join
            else
              transformed
            end
          rescue Parslet::ParseFailed
            text
          end
        end
      end
    end
  end
end
