# frozen_string_literal: true

module Coradoc
  module Model
    module Image
      class Core < Coradoc::Model::Base
        attribute :id, :string
        attribute :title, :string
        attribute :src, :string
        attribute :attributes, Coradoc::Model::AttributeList, default: -> {
          Coradoc::Model::AttributeList.new
        }
        attribute :anchor, Coradoc::Model::Inline::Anchor, default: -> {
          id.nil? ? nil : Coradoc::Model::Inline::Anchor.new(id)
        }
        attribute :annotate_missing, :string
        attribute :line_break, :string, default: -> { "" }
        attribute :colons, :string

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
