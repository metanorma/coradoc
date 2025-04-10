# frozen_string_literal: true

module Coradoc
  module Model
    class Tag < Base
      attribute :name, :string
      attribute :prefix, :string, default: "tag"
      attribute :attrs, AttributeList, default: -> { AttributeList.new }
      attribute :line_break, :string, default: "\n"

      # asciidoc do
      #   map_attribute "attrs", to: :attrs
      #   map_attribute "prefix", to: :prefix
      #   map_attribute "line_break", to: :line_break
      # end

      def to_asciidoc
        attrs_str = attrs.to_asciidoc
        "// #{prefix}::#{name}#{attrs_str}#{line_break}"
      end
    end
  end
end
