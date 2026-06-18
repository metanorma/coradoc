# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class AttributeList < ElementSerializer
          handles_type ::Coradoc::Markdown::AttributeList

          def call(element, _ctx)
            return '' if element.empty?

            parts = []
            parts << "##{element.id}" if element.id
            parts += element.classes.map { |c| ".#{c}" }
            parts += element.attributes.map { |nv| %(#{nv.name}="#{nv.value}") }
            "{:#{parts.join(' ')}}"
          end
        end
      end
    end
  end
end
