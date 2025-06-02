# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class CrossReferenceArg < Base
        attribute :key, :string
        attribute :delimiter, :string
        attribute :value, :string

        asciidoc do
          map_model to: Coradoc::Element::Inline::CrossReferenceArg
          map_attribute "key", to: :key
          map_attribute "delimiter", to: :delimiter
          map_attribute "value", to: :value
        end

        def to_asciidoc
          [key, delimiter, value].join
        end
      end
    end
  end
end
