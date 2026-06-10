# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Visits AsciiDoc inline model nodes and extracts plain text.
      #
      # Replaces the 70-line extract_text_content case/when in ToCoreModel.
      # Each visit_ method handles one model type — locality per element.
      class TextExtractVisitor
        def extract(model)
          visit(model)
        end

        private

        # Scalars
        def visit_nil(_)
          ''
        end

        def visit_string(model)
          model
        end

        def visit_parslet_slice(model)
          model.to_s
        end

        # Text carriers
        def visit_text_element(model)
          content = model.content
          content.is_a?(Array) ? visit_array(content) : visit(content)
        end

        # Inline formatting — recurse into content
        def visit_inline(model)
          visit(model.content)
        end

        def visit_term(model)
          model.term.to_s
        end

        def visit_link(model)
          model.name || model.path || ''
        end

        def visit_cross_reference(model)
          model.href || ''
        end

        def visit_stem(model)
          model.content.to_s
        end

        def visit_footnote(model)
          model.text ? visit(model.text) : ''
        end

        def visit_attribute_reference(model)
          "{#{model.name}}"
        end

        def visit_core_model_text_content(model)
          model.text.to_s
        end

        def visit_core_model_image(model)
          model.alt || model.src || ''
        end

        def visit_adoc_image(model)
          model.alt || model.src || ''
        end

        def visit_base_model(model)
          model.content ? visit(model.content) : ''
        end

        def visit_core_model_inline(model)
          model.content.to_s
        end

        # Collections
        def visit_array(models)
          result = []
          models.each_with_index do |item, idx|
            text = visit(item)
            next if text.empty?

            result << text
            next unless idx < models.length - 1 && !text.empty?

            result << ' ' if item.is_a?(Model::TextElement) && item.line_break != '+'
          end
          result.join
        end

        # Dispatch
        def visit(model)
          case model
          when nil then visit_nil(model)
          when String then visit_string(model)
          when Parslet::Slice then visit_parslet_slice(model)
          when CoreModel::TextContent then visit_core_model_text_content(model)
          when CoreModel::Image then visit_core_model_image(model)
          when CoreModel::InlineElement then visit_core_model_inline(model)
          when Array then visit_array(model)
          when Model::TextElement then visit_text_element(model)
          when Model::Term then visit_term(model)
          when Model::Inline::Link then visit_link(model)
          when Model::Inline::CrossReference then visit_cross_reference(model)
          when Model::Inline::Stem then visit_stem(model)
          when Model::Inline::Footnote then visit_footnote(model)
          when Model::Inline::AttributeReference then visit_attribute_reference(model)
          when Model::Image::Core then visit_adoc_image(model)
          when Model::Base then visit_base_model(model)
          else
            model.class.name.start_with?('Parslet::') ? model.to_s : ''
          end
        end
      end
    end
  end
end
