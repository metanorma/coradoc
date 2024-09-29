module Coradoc
  module Element
    class TextElement < Base
      attr_accessor :id, :content, :line_break

      declare_children :content

      def initialize(content, options = {})
        @content = content # .to_s
        @id = options.fetch(:id, nil)
        @line_break = options.fetch(:line_break, "")
        @html_cleanup = options.fetch(:html_cleanup, false)
        if @html_cleanup
          @content = treat_text_to_adoc(@content)
        end
      end

      def inspect
        str = "TextElement"
        str += "(#{@id})" if @id
        str += ": "
        str += @content.inspect
        str += " + #{@line_break.inspect}" unless line_break.empty?
        str
      end

      def to_adoc
        Coradoc::Generator.gen_adoc(@content) + @line_break
      end

      def treat_text_to_adoc(text)
        text = preserve_nbsp(text)
        text = remove_border_newlines(text)
        text = remove_inner_newlines(text)
        text = self.class.escape_keychars(text)

        text = preserve_keychars_within_backticks(text)
        escape_links(text)
      end

      def preserve_nbsp(text)
        text.gsub(/\u00A0/, "&nbsp;")
      end

      def escape_links(text)
        text.gsub(/<<([^ ][^>]*)>>/, "\\<<\\1>>")
      end

      def remove_border_newlines(text)
        text.gsub(/\A\n+/, "").gsub(/\n+\z/, "")
      end

      def remove_inner_newlines(text)
        text.tr("\n\t", " ").squeeze(" ")
      end

      def preserve_keychars_within_backticks(text)
        text.gsub(/`.*?`/) do |match|
          match.gsub('\_', "_").gsub('\*', "*")
        end
      end

      def self.escape_keychars(string)
        subs = { "*" => '\*', "_" => '\_' }
        string
          .gsub(/((?<=\s)[\*_]+)|[\*_]+(?=\s)/) do |n|
          n.chars.map do |char|
            subs[char]
          end.join
        end
      end
    end

    class LineBreak < Base
      attr_reader :line_break

      def initialize(line_break)
        @line_break = line_break
      end

      def to_adoc
        @line_break
      end
    end

    class Highlight < Element::TextElement
    end
  end
end
