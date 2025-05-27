# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Span < Base
        attribute :text, :string
        attribute :role, :string
        attribute :attributes, AttributeList
        attribute :unconstrained, :boolean, default: -> { false }

        def to_asciidoc
          if attributes
            attr_string = attributes.to_asciidoc
            if unconstrained
              "#{attr_string}###{text}##"
            else
              "#{attr_string}##{text}#"
            end
          elsif role
            if unconstrained
              "[.#{role}]###{text}##"
            else
              "[.#{role}]##{text}#"
            end
          else
            text.to_s
          end
        end
      end
    end
  end
end
