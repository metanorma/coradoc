# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Pre < Base
        INSTANCE = new

        def to_coradoc(node, _state = {})
          id = node['id']
          lang = language(node)
          content = extract_text_content(node)

          if lang
            Coradoc::CoreModel::SourceBlock.new(
              content: content,
              id: id,
              language: lang
            )
          else
            Coradoc::CoreModel::LiteralBlock.new(
              content: content,
              id: id
            )
          end
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

          # Extract language from brush: language; pattern — index +
          # linear scan (CodeQL rb/polynomial-redos: /\s*[^;]+/ has
          # overlapping quantifiers).
          rest = class_str[(class_str.index('brush:') + 6)..].to_s
          lang = rest.lstrip[/\A([^;]+);/, 1]
          lang&.strip
        end
      end

      register :pre, Pre::INSTANCE
    end
  end
end
