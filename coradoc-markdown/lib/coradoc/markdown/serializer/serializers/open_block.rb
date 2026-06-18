# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        # Open block: emits children inline unless id/classes are present,
        # in which case it wraps them in an HTML `<div>`.
        class OpenBlock < ElementSerializer
          handles_type ::Coradoc::Markdown::OpenBlock

          def call(element, ctx)
            children_md = element.children.map { |c| ctx.serialize(c) }.join("\n\n")
            return children_md unless needs_wrapper?(element)

            attrs = wrapper_attrs(element)
            %(<div#{attrs}>\n#{children_md}\n</div>)
          end

          private

          def needs_wrapper?(element)
            element.id || (element.classes && element.classes.any?)
          end

          def wrapper_attrs(element)
            parts = []
            parts << %(id="#{element.id}") if element.id
            element.classes&.each { |c| parts << %(class="#{c}") }
            parts.empty? ? '' : " #{parts.join(' ')}"
          end
        end
      end
    end
  end
end
