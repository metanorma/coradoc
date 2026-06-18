# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Extension < ElementSerializer
          handles_type ::Coradoc::Markdown::Extension

          def call(element, _ctx)
            opts = element.options.empty? ? '' : " #{extension_options_to_s(element.options)}"
            if element.self_closing?
              "{::#{element.name}#{opts} /}"
            else
              "{::#{element.name}#{opts}}#{element.content}{:/}"
            end
          end

          private

          def extension_options_to_s(options)
            options.map { |nv| %(#{nv.name}="#{nv.value}") }.join(' ')
          end
        end
      end
    end
  end
end
