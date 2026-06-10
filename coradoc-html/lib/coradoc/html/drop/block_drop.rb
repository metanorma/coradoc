# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class BlockDrop < Base
        def semantic_type
          resolved_semantic_type.to_s
        end

        def html_tag
          TagMapping.tag_for(resolved_semantic_type)
        end

        def language
          @model.language || @model.metadata('language')
        end

        def css_class
          cls = TagMapping.css_class_for(resolved_semantic_type)
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

      DropFactory.register(CoreModel::Block, BlockDrop)
    end
  end
end
