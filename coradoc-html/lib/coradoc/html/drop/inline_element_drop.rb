# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class InlineElementDrop < Base
        def format_type
          @model.resolve_format_type
        end

        def html_tag
          TagMapping.tag_for(format_type)
        end

        def href
          case format_type
          when 'link'
            @model.target || @model.metadata('href') || '#'
          when 'xref'
            target = @model.target || @model.metadata('href') || ''
            "##{target}"
          end
        end

        def text
          Escape.escape_html(extract_text(@model.content))
        end

        def css_class
          return @model.metadata('class') if format_type == 'span'

          TagMapping.css_class_for(format_type)
        end

        def term_ref
          @model.content.to_s if format_type == 'term'
        end
      end

      DropFactory.register(CoreModel::InlineElement, InlineElementDrop)
    end
  end
end
