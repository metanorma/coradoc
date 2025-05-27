# frozen_string_literal: true

module Coradoc
  module Model
    class Title < Base
      include Coradoc::Model::Anchorable

      attribute :id, :string
      attribute :content, :string
      # attribute :level, :string
      attribute :level_int, :integer
      attribute :line_break, :string, default: -> { "\n" }
      attribute :style, :string

      alias :text :content

      asciidoc do
        map_content to: :content
        map_attribute "id", to: :id
        map_attribute "level", to: :level_int
        map_attribute "style", to: :style
        map_attribute "anchor", to: :anchor
      end

      def to_asciidoc
        _anchor = anchor.nil? ? "" : "#{anchor.to_asciidoc}\n"
        _content = Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(content))
        <<~HERE

          #{_anchor}#{style_str}#{level_str} #{_content}
        HERE
      end

      def level_str
        return if level_int.nil?

        if level_int <= 5
          "=" * (level_int + 1)
        else
          "======"
        end
      end

      def style_str
        return if level_int.nil?

        _style = [style]
        _style << "level=#{level_int}" if level_int > 5
        _style = _style.compact.join(",")

        "[#{_style}]\n" unless _style.empty?
      end
    end
  end
end
