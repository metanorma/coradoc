# frozen_string_literal: true

module Coradoc
  module Model
    class Admonition < Attached
      attribute :content, :string
      attribute :type, :string
      attribute :line_break, :string, default: -> { "" }

      asciidoc do
        map_model to: Coradoc::Element::Admonition
        map_content to: :content
        map_attribute "type", to: :type
      end

      def to_asciidoc
        _content = Coradoc::Generator.gen_adoc(content)
        "#{type.to_s.upcase}: #{_content}#{line_break}"
      end
    end
  end
end
