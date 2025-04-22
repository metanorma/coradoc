# frozen_string_literal: true

module Coradoc
  module Model
    class Video < Base
      attribute :id, :string
      attribute :title, :string
      attribute :src, :string, default: -> { "" }
      attribute :anchor, Inline::Anchor, default: -> {
        id.nil? ? nil : Inline::Anchor.new(id)
      }
      attribute :attributes, AttributeList, default: -> { AttributeList.new }

      def to_asciidoc
        _anchor = anchor.nil? ? "" : "#{anchor.to_asciidoc}\n"
        _title = ".#{title}\n" unless title.empty?
        _attrs = attributes.to_asciidoc
        [_anchor, _title, "video::", src, _attrs].join
      end
    end
  end
end
