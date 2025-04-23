# frozen_string_literal: true

module Coradoc
  module Model
    class Video < Base
      include Coradoc::Model::Anchorable

      attribute :id, :string
      attribute :title, :string
      attribute :src, :string, default: -> { "" }
      # attribute :anchor, Inline::Anchor, default: -> {
      #   id.nil? ? nil : Inline::Anchor.new(id)
      # }
      attribute :attributes, AttributeList, default: -> { AttributeList.new }

      asciidoc do
        map_attribute "id", to: :id
        map_attribute "title", to: :title
        map_attribute "src", to: :src
        map_attribute "attributes", to: :attributes
        map_attribute "anchor", to: :anchor
      end

      def to_asciidoc
        _anchor = anchor.nil? ? "" : "#{anchor.to_asciidoc}\n"
        _title = ".#{title}\n" unless title.empty?
        _attrs = attributes.to_asciidoc
        [_anchor, _title, "video::", src, _attrs].join
      end
    end
  end
end
