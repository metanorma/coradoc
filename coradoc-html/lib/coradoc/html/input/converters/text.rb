# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Text < Base
          def to_coradoc(node, state = {})
            return treat_empty(node, state) if node.text.strip.empty?

            # HTML cleanup is performed in the converter layer
            cleaned_content = cleanup_html_text(node.text)

            # Return as CoreModel::InlineElement with format_type "text"
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'text',
              content: cleaned_content
            )
          end

          private

          def treat_empty(node, state)
            parent = node.parent.name.to_sym
            if %i[ol ul].include?(parent) # Otherwise the indentation is broken
              nil
            elsif state[:tdsinglepara]
              nil
            elsif node.text == ' ' # Regular whitespace text node
              ' '
            else
              nil
            end
          end

          # HTML-to-CoreModel text cleanup
          def cleanup_html_text(text)
            text = preserve_nbsp(text)
            text = remove_border_newlines(text)
            text = remove_inner_newlines(text)
            escape_links(text)
          end

          def preserve_nbsp(text)
            text.gsub("\u00A0", '&nbsp;')
          end

          def escape_links(text)
            text.gsub(/<<([^ ][^>]*)>>/, '\\<<\\1>>')
          end

          def remove_border_newlines(text)
            text.gsub(/\A\n+/, '').gsub(/\n+\z/, '')
          end

          def remove_inner_newlines(text)
            # Convert newlines/tabs to spaces and squeeze multiple spaces
            # Preserve single leading/trailing space for inline contexts
            text.tr("\n\t", ' ').squeeze(' ')
          end
        end

        register :text, Text.new
      end
    end
  end
end
