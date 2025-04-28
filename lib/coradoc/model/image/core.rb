# frozen_string_literal: true

require_relative "core/attribute_list"

module Coradoc
  module Model
    module Image
      class Core < Coradoc::Model::Base
        include Coradoc::Model::Anchorable

        attribute :id, :string
        attribute :title, :string
        attribute :src, :string
        attribute :attributes, Coradoc::Model::Image::Core::AttributeList, default: -> {
          Coradoc::Model::Image::Core::AttributeList.new
        }
        attribute :annotate_missing, :string
        attribute :line_break, :string, default: -> { "" }
        attribute :colons, :string

        asciidoc do
          map_attribute "id", to: :id
          map_attribute "title", to: :title
          map_attribute "src", to: :src
          map_attribute "attributes", to: :attributes
          map_attribute "anchor", to: :anchor
          map_attribute "annotate_missing", to: :annotate_missing
          map_attribute "line_break", to: :line_break
          map_attribute "colons", to: :colons
        end

        def to_asciidoc
          missing = if annotate_missing
                      "// FIXME: Missing image: #{annotate_missing}\n"
                    else
                      ""
                    end
          _anchor = anchor.nil? ? "" : "#{anchor.to_asciidoc}\n"
          _title = ".#{title}\n" unless title.to_s.empty?
          # XXX: what is attributes_macro?
          # attrs = attributes_macro.to_asciidoc
          attrs = attributes.to_asciidoc
          [missing, _anchor, _title, "image", colons, src, attrs,
           line_break].join
        end
      end
    end
  end
end
