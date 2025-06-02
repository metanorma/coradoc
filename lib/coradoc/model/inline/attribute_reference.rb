# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class AttributeReference < Base
        attribute :name, :string

        asciidoc do
          map_model to: Coradoc::Element::Inline::AttributeReference
          map_attribute "name", to: :name
        end

        def to_asciidoc
          "{#{name}}"
        end
      end
    end
  end
end
