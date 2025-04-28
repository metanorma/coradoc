# frozen_string_literal: true

module Coradoc
  module Model
    class ListItem < Base
      include Coradoc::Model::Anchorable

      attribute :id, :string
      attribute :content, Coradoc::Model::Base, polymorphic: [
        Coradoc::Model::TextElement,
        Coradoc::Model::Section,
      ]
      attribute :marker, :string
      attribute :subitem, :string
      attribute :line_break, :string

      attribute :attached, Coradoc::Model::Attached, polymorphic: [
        Coradoc::Model::Admonition,
        Coradoc::Model::Paragraph,
        Coradoc::Model::Block::Core,
      ], collection: true, initialize_empty: true

      attribute :nested, Coradoc::Model::List::Nestable

      asciidoc do
        map_content to: :content
        map_attribute "id", to: :id
        map_attribute "anchor", to: :anchor
        map_attribute "marker", to: :marker
        map_attribute "subitem", to: :subitem
      end

      HARDBREAK_MARKERS = %i[hardbreak init].freeze
      STRIP_UNICODE_BEGIN_MARKERS = (HARDBREAK_MARKERS.dup + [false]).freeze
      STRIP_UNICODE_END_MARKERS = [:hardbreak, :end, false].freeze

      def inline?(elem)
        case elem
        when Inline::HardLineBreak
          :hardbreak
        when ->(i) { i.class.name.to_s.include? "::Inline::" }
          true
        when String, TextElement, Image::InlineImage
          true
        else
          false
        end
      end

      def to_asciidoc
        _anchor = gen_anchor(inline: true)
        _content = Array(content).dup.flatten.compact # ???
        # content = Array(@content).flatten.compact
        out = ""
        prev_inline = :init

        # Collapse meaningless <DIV>s
        while
          _content.map(&:class) == [Section] &&
              _content.first.safe_to_collapse?

          _content = Array(_content.first.contents)
        end

        _content.each_with_index do |subitem, idx|
          puts "genning subitem #{idx} of #{subitem.class}"
          subcontent = Coradoc::Generator.gen_adoc(subitem)

          inline = inline?(subitem)
          next_inline = idx + 1 == _content.length ? :end : inline?(_content[idx + 1])

          # Only try to postprocess elements that are text,
          # otherwise we could strip markup.
          if subitem.is_a? Coradoc::Model::TextElement
            puts "subitem is a text!!!!"
            if STRIP_UNICODE_BEGIN_MARKERS.include?(prev_inline)
              subcontent = Coradoc.strip_unicode(subcontent, only: :begin)
            end
            if STRIP_UNICODE_END_MARKERS.include?(next_inline)
              subcontent = Coradoc.strip_unicode(subcontent, only: :end)
            end
          end

          case inline
          when true
            out += if prev_inline == false
                     "\n+\n#{subcontent}"
                   else
                     subcontent
                   end
          when false
            out += case prev_inline
                   when :hardbreak
                     subcontent.strip
                   when :init
                     "{empty}\n+\n#{subcontent.strip}"
                   else
                     "\n+\n#{subcontent.strip}"
                   end
          when :hardbreak
            if HARDBREAK_MARKERS.include?(prev_inline)
              # can't have two hard breaks in a row
              # can't start with a hard break
            else
              out += "\n+\n"
            end
          end

          prev_inline = inline
        end
        out += "{empty}" if prev_inline == :hardbreak
        out = "{empty}" if out.empty?

        # attach = Coradoc::Generator.gen_adoc(@attached)
        attach = attached.map do |elem|
          "+\n#{Coradoc::Generator.gen_adoc(elem)}"
        end.join
        nest = Coradoc::Generator.gen_adoc(nested)
        puts 'pp nested'
        pp nested
        puts 'pp nest'
        pp nest
        out = " #{_anchor}#{out}#{line_break}"
        pp [out, attach, nest]
        out + attach + nest
      end
    end
  end
end
