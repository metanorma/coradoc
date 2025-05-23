# frozen_string_literal: true

module Coradoc
  module Model
    class Audio < Base
      include Coradoc::Model::Anchorable

      attribute :id, :string
      attribute :title, :string
      attribute :src, :string, default: -> { "" }
      attribute :attributes, AttributeList, default: -> { AttributeList.new }
      attribute :line_break, :string, default: -> { "\n" }

      asciidoc do
        map_attribute "id", to: :id
        map_attribute "title", to: :title
        map_attribute "src", to: :src
        map_attribute "attributes", to: :attributes
        map_attribute "anchor", to: :anchor
      end

      def to_asciidoc
        _anchor = gen_anchor
        _title = ".#{title}\n" unless title.nil? || title.empty?
        _attrs = attributes.empty? ? "[]" : attributes.to_asciidoc
        [_anchor, _title, "audio::", src, _attrs].join + line_break
      end
    end
  end
end
