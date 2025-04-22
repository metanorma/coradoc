# frozen_string_literal: true

module Coradoc
  module Model
    class Title < Base
      attribute :id, :string
      attribute :content, :string
      # attribute :level, :string
      attribute :level_int, :integer
      attribute :line_break, :string, default: -> { "\n" }
      attribute :style, :string
      attribute :anchor, Inline::Anchor, default: -> {
        id.nil? ? nil : Inline::Anchor.new(id)
      }

      asciidoc do
        map_content to: :content
        map_attribute "id", to: :id
      end

      def to_asciidoc
        _anchor = anchor.nil? ? "" : "#{anchor.to_adoc}\n"
        _content = Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(content))
        <<~HERE

          #{_anchor}#{style_str}#{level_str} #{_content}
        HERE
      end

      def level_str
        if level_int <= 5
          "=" * (level_int + 1)
        else
          "======"
        end
      end

      def style_str
        _style = [style]
        _style << "level=#{level_int}" if level_int > 5
        _style = _style.compact.join(",")

        "[#{_style}]\n" unless _style.empty?
      end
    end
  end
end
