# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class InlineElementDrop < Base
        FORMAT_TAG_MAP = {
          'bold' => 'strong',
          'italic' => 'em',
          'monospace' => 'code',
          'superscript' => 'sup',
          'subscript' => 'sub',
          'underline' => 'u',
          'strikethrough' => 'del',
          'highlight' => 'mark',
          'quotation' => 'q',
          'small' => 'small',
          'stem' => 'code'
        }.freeze

        def format_type
          @model.resolve_format_type
        end

        def html_tag
          case format_type
          when 'link', 'xref' then 'a'
          when 'footnote' then 'sup'
          when 'span', 'term' then 'span'
          else FORMAT_TAG_MAP[format_type]
          end
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
          case format_type
          when 'stem' then 'stem'
          when 'term' then 'term'
          when 'span' then @model.metadata('class')
          end
        end

        def term_ref
          @model.content.to_s if format_type == 'term'
        end
      end

      DropFactory.register(CoreModel::InlineElement, InlineElementDrop)
    end
  end
end
