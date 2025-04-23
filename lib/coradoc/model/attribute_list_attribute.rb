# frozen_string_literal: true

module Coradoc
  module Model
    class AttributeListAttribute < Base
      attribute :value, :string

      asciidoc do
        map_attribute "value", to: :value
      end

      def to_asciidoc
        [nil, ""].include?(value) ? '""' : value
      end
    end
  end
end
