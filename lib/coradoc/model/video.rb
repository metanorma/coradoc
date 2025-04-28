# frozen_string_literal: true

require_relative "video/attribute_list"
module Coradoc
  module Model
    class Video < Base
      include Coradoc::Model::Anchorable

      attribute :id, :string
      attribute :title, :string
      attribute :src, :string, default: -> { "" }
      attribute :attributes, Video::AttributeList, default: -> { Video::AttributeList.new }

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
        _attrs = attributes.to_asciidoc
        [_anchor, _title, "video::", src, _attrs].join
      end
    end
  end
end
