# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class Core < Base
            def to_adoc(model, _options = {})
              @model = model
              "\n\n#{gen_anchor}#{gen_title}#{gen_attributes}#{gen_delimiter}\n" <<
                gen_lines << "\n#{gen_delimiter}\n\n"
            end

            private

            attr_reader :model

            def gen_title
              t = serialize_children(model.title)
              return '' if t.nil? || t.empty?

              ".#{t}\n"
            end

            def gen_attributes
              return '' if model.attributes.nil?

              attrs = model.attributes.to_adoc(show_empty: false)
              return "#{attrs}\n" unless attrs.empty?

              ''
            end

            def gen_delimiter
              return '' if model.delimiter_char.nil? || model.delimiter_len.nil?

              model.delimiter_char.to_s * model.delimiter_len
            end

            def gen_lines
              # Handle both String and model object lines
              result = model.lines.map do |line|
                serialized = serialize_child(line)
                # Add newline if line is a plain string without one
                serialized.is_a?(String) && !serialized.end_with?("\n") ? "#{serialized}\n" : serialized
              end.join
              # Remove trailing newline to avoid extra blank line before delimiter
              result.chomp
            end

            def gen_anchor
              return '' unless @model.anchor

              anchor_str = if @model.anchor.respond_to?(:to_adoc)
                             @model.anchor.to_adoc
                           else
                             @model.anchor.to_s
                           end
              "#{anchor_str}\n"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Block::Core, Block::Core)
      end
    end
  end
end
