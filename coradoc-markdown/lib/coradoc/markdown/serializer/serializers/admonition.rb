# frozen_string_literal: true

require_relative '../element_serializer'
require_relative '../strategies/admonition/registry'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Admonition < ElementSerializer
          handles_type ::Coradoc::Markdown::Admonition

          def call(element, ctx)
            Strategies::Admonition::Registry.render(element, ctx: ctx)
          end
        end
      end
    end
  end
end
