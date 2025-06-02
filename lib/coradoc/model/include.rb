# frozen_string_literal: true

module Coradoc
  module Model
    class Include < Base
      attribute :path, :string
      attribute :attributes, AttributeList, default: -> { AttributeList.new }
      attribute :line_break, :string, default: -> { "\n" }

      asciidoc do
        map_model to: Coradoc::Element::Include
        map_attribute "path", to: :path
        map_attribute "attributes", to: :attributes
      end

      def to_asciidoc
        attrs = attributes.to_asciidoc(show_empty: true)
        "include::#{path}#{attrs}#{line_break}"
      end
    end
  end
end
