# frozen_string_literal: true

module Coradoc
  module Markdown
    module Bindings
      # Document-scoped state for the stateful rules: the Attribute List
      # Definition table. One Scope per parsed document, handed to the
      # scoped hooks by the BindingInflater.
      class Scope
        def initialize
          @definitions = {}
        end

        # Register an ALD under its name.
        def define(name, attrs)
          @definitions[name] = Bindings.model('AttributeList').new(name: name, **attrs)
        end

        # An IAL naming a registered ALD resolves to it; anything else is
        # a fresh attribute list.
        def resolve(ial_content)
          content = ial_content.strip
          return @definitions[content] if content.match?(/\A\w+\z/) && @definitions.key?(content)

          attrs = Captures.parse_ial_content(content)
          Bindings.model('AttributeList').new(id: attrs[:id], classes: attrs[:classes], attributes: attrs[:attributes])
        end
      end
    end
  end
end
