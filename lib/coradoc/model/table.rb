# frozen_string_literal: true

module Coradoc
  module Model
    class Table < Base
      include Coradoc::Model::Anchorable

      attribute :id, :string
      attribute :title, :string
      attribute :rows, :string
      attribute :content, :string
      # attribute :anchor, Inline::Anchor, default: -> {
      #   id.nil? ? nil : Inline::Anchor.new(id)
      # }
      attribute :attrs, AttributeList

      asciidoc do
        map_content to: :content
        map_attribute "title", to: :title
        map_attribute "rows", to: :rows
        map_attribute "id", to: :id
        map_attribute "anchor", to: :anchor
        map_attribute "attrs", to: :attrs
      end

      def to_asciidoc
        _anchor = anchor.nil? ? "" : "#{anchor.to_asciidoc}\n"
        _attrs = attrs.to_s.empty? ? "" : "#{attrs.to_asciidoc}\n"
        _title = Coradoc::Generator.gen_adoc(title)
        _title = _title.empty? ? "" : ".#{_title}\n"
        _content = rows.map(&:to_asciidoc).join
        "\n\n#{_anchor}#{attrs}#{_title}|===\n" << _content << "\n|===\n"
      end
    end
  end
end
