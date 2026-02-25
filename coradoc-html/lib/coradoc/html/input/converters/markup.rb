# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Markup < Base
          def to_coradoc(node, state = {})
            u_before = unconstrained_before?(node)
            u_after = unconstrained_after?(node)

            leading_ws, trailing_ws =
              extract_leading_trailing_whitespace(node)

            # Wrap whitespace in InlineElement so it can be processed
            leading_whitespace = if leading_ws
                                   Coradoc::CoreModel::InlineElement.new(
                                     format_type: 'text',
                                     content: leading_ws
                                   )
                                 end
            trailing_whitespace = if trailing_ws
                                    Coradoc::CoreModel::InlineElement.new(
                                      format_type: 'text',
                                      content: trailing_ws
                                    )
                                  end

            content = treat_children_coradoc(node, state)

            if node_has_ancestor?(node, markup_ancestor_tag_names)
              content
            elsif node.children.empty?
              # Return InlineElement wrapper for whitespace
              if leading_ws
                Coradoc::CoreModel::InlineElement.new(
                  format_type: 'text',
                  content: leading_ws
                )
              end
            else
              u = (u_before && leading_whitespace.nil?) ||
                  (u_after && trailing_whitespace.nil?)

              # Separate text strings from InlineElements in content array
              text_content, nested = extract_text_and_elements(content)

              # Create CoreModel::InlineElement with the appropriate format type
              inline_element = Coradoc::CoreModel::InlineElement.new(
                format_type: coradoc_format_type,
                content: text_content,
                nested_elements: nested.empty? ? nil : nested,
                metadata: { unconstrained: u }
              )
              result = [leading_whitespace, inline_element, trailing_whitespace].compact
              result.length == 1 ? result.first : result
            end
          end

          # Extract text content and InlineElements from mixed content array
          def extract_text_and_elements(content)
            return [content, []] unless content.is_a?(Array)

            text_parts = []
            elements = []

            content.each do |item|
              case item
              when String
                text_parts << item
              when Coradoc::CoreModel::InlineElement
                elements << item
              when Coradoc::CoreModel::Base
                # For other block types, convert to text
                text_parts << extract_text_from_model(item)
              else
                text_parts << item.to_s
              end
            end

            [text_parts.join, elements]
          end

          # Extract text from a CoreModel object
          def extract_text_from_model(model)
            return '' if model.nil?

            if model.respond_to?(:content) && model.content.is_a?(String)
              model.content
            elsif model.respond_to?(:children) && model.children.is_a?(Array)
              model.children.map { |c| extract_text_from_model(c) }.join
            elsif model.respond_to?(:title) && model.title.is_a?(String)
              model.title
            else
              model.to_s
            end
          end

          # Subclasses should override this to return the format type
          def coradoc_format_type
            'text'
          end
        end
      end
    end
  end
end
