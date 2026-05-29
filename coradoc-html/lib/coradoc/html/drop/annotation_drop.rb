# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Html
    module Drop
      class AnnotationDrop < Base
        def template_type
          'annotation_block'
        end

        def annotation_type
          (@model.annotation_type || 'note').to_s.downcase
        end

        def label
          Escape.escape_html(@model.annotation_label || annotation_type.upcase)
        end

        def content
          content_to_liquid(@model.renderable_content)
        end

        def css_class
          "admonitionblock #{annotation_type}"
        end
      end
    end
  end
end
