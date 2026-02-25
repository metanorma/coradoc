# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Serializer for Paragraph models
        class Paragraph < Base
          def to_adoc(model, options_or_context = {})
            context = normalize_context(options_or_context)

            _title = model.title.nil? ? '' : ".#{serialize_child(model.title, context)}\n"
            _anchor = gen_anchor(model, context)
            attrs = if model.attributes.nil? || model.attributes.empty?
                      ''
                    else
                      "#{AdocSerializer.serialize(
                        model.attributes, context
                      )}\n"
                    end

            result = if model.tdsinglepara
                       "#{_title}#{_anchor}" <<
                         serialize_content(model.content)
                     else
                       "#{_title}#{_anchor}#{attrs}" <<
                         serialize_content(model.content)
                     end

            # Ensure paragraph ends with blank line for proper separation
            # unless this is the last element in a document (determined by context)
            # But not for tdsinglepara (table cell single paragraph)
            unless model.tdsinglepara || context.last_element
              if model.trailing_newlines.nil?
                # Semantic mode: Use default "\n\n" ending
                result = "#{result.chomp}\n\n" unless result.end_with?("\n\n")
              else
                # Exact mode: Use captured trailing newlines from original
                result += model.trailing_newlines
              end
            end

            result
          end

          private

          def gen_anchor(model, context)
            return '' if model.anchor.nil? || model.id.nil? || model.id.empty?

            anchor_str = AdocSerializer.serialize(model.anchor, context)
            if anchor_str.empty?
              ''
            else
              "#{anchor_str}\n"
            end
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Paragraph, Serializers::Paragraph)
    end
  end
end
