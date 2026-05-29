# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Html
    module Drop
      class BlockDrop < Base
        SEMANTIC_TAG_MAP = {
          paragraph: 'p', source_code: 'pre', quote: 'blockquote',
          verse: 'blockquote', example: 'div', sidebar: 'aside',
          literal: 'pre', listing: 'pre', open: 'div',
          horizontal_rule: 'hr'
        }.freeze

        SEMANTIC_CLASS_MAP = {
          example: 'example', sidebar: 'sidebar', literal: 'literal'
        }.freeze

        def semantic_type
          resolved_semantic_type.to_s
        end

        def html_tag
          SEMANTIC_TAG_MAP[resolved_semantic_type] || 'div'
        end

        def language
          @model.language || @model.metadata('language')
        end

        def css_class
          cls = SEMANTIC_CLASS_MAP[resolved_semantic_type]
          cls ? "block-#{semantic_type} #{cls}" : "block-#{semantic_type}"
        end

        def content
          content_to_liquid(@model.renderable_content)
        end

        def text
          if %i[source_code literal listing].include?(resolved_semantic_type)
            Escape.escape_html(@model.flat_text)
          elsif resolved_semantic_type == :pass
            @model.flat_text.to_s
          end
        end

        def hidden?
          %i[comment reviewer].include?(resolved_semantic_type)
        end

        def raw?
          resolved_semantic_type == :pass
        end

        def hr?
          resolved_semantic_type == :horizontal_rule
        end

        private

        def resolved_semantic_type
          @resolved_semantic_type ||= @model.resolve_semantic_type || :paragraph
        end
      end
    end
  end
end
