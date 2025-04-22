# frozen_string_literal: true

module Coradoc
  module Model
    class ListItemDefinition < Base
      attribute :id, :string
      attribute :anchor, Inline::Anchor, default: -> {
        id.nil? ? nil : Inline::Anchor.new(id)
      }
      attribute :contents, :string
      attribute :terms, Coradoc::Model::Term, collection: true

      asciidoc do
        map_attribute "id", to: :id
        map_attribute "anchor", to: :anchor
        map_attribute "contents", to: :contents
        map_attribute "terms", to: :terms
      end

      def to_asciidoc(delimiter)
        _anchor = anchor.nil? ? "" : anchor.to_asciidoc.to_s
        content = ""
        if terms.size == 1
          t = Coradoc::Generator.gen_adoc(terms)
          content << "#{_anchor}#{t}#{delimiter} "
        else
          terms.map do |term|
            t = Coradoc::Generator.gen_adoc(term)
            content << "#{t}#{delimiter}\n"
          end
        end
        d = Coradoc::Generator.gen_adoc(contents)
        content << "#{d}\n"
      end
    end
  end
end
