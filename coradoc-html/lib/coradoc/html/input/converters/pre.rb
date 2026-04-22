# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Pre < Base
          def to_coradoc(node, _state = {})
            id = node['id']
            lang = language(node)
            content = extract_text_content(node)

            delimiter_type = lang ? '----' : '....'
            element_type = lang ? 'source' : 'literal'

            Coradoc::CoreModel::Block.new(
              element_type: element_type,
              delimiter_type: delimiter_type,
              content: content,
              id: id,
              language: lang
            )
          end

          private

          def extract_text_content(node)
            # Get text content from pre node
            node.text
          end

          def language(node)
            lang = language_from_highlight_class(node)
            lang || language_from_confluence_class(node)
          end

          def language_from_highlight_class(node)
            node.parent['class'].to_s[/highlight-([a-zA-Z0-9]+)/, 1]
          end

          def language_from_confluence_class(node)
            class_str = node['class'].to_s
            return nil unless class_str.include?('brush:')

            # Extract language from brush: language; pattern
            match = class_str.match(/brush:\s*([^;]+);/)
            match ? match[1].strip : nil
          end
        end

        register :pre, Pre.new
      end
    end
  end
end
