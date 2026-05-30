# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class DocumentDrop < Base
        include SectionNumberable

        def template_type
          return 'document' if @model.is_a?(CoreModel::DocumentElement)

          'section'
        end

        def title
          text = TitleText.resolve(@model.title)
          return nil unless text && !text.empty?

          if @section_number
            Escape.escape_html("#{@section_number}. #{text}")
          else
            Escape.escape_html(text)
          end
        end

        def children
          children_to_liquid(@model.children)
        end

        def structural_type
          case @model
          when CoreModel::DocumentElement then 'document'
          when CoreModel::SectionElement then 'section'
          when CoreModel::HeaderElement then 'header'
          when CoreModel::PreambleElement then 'preamble'
          else 'structural'
          end
        end

        def heading_level
          if @model.is_a?(CoreModel::SectionElement)
            [@model.heading_level + 1, 6].min
          else
            1
          end
        end
      end

      DropFactory.register(CoreModel::StructuralElement, DocumentDrop)
    end
  end
end
