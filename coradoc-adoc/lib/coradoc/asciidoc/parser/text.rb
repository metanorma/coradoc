# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      module Text
        def space?
          space.maybe
        end

        def space
          str(' ').repeat(1)
        end

        def text
          match("[^\n]").repeat(1)
        end

        def line_start?
          match('^[^\n]').present?
        end

        def line_ending
          str("\n") # | match('[\z]')# | match('$')
        end

        def eof?
          any.absent?
        end

        def line_end
          str("\n") | str("\r\n") | eof?
        end

        def endline
          newline | any.absent?
        end

        # def endline_single
        #   newline_single | any.absent?
        # end

        def newline
          (str("\n") | str("\r\n")).repeat(1)
        end

        def newline_single
          (str("\n") | str("\r\n"))
        end

        def keyword
          (match('[a-zA-Z0-9_\-.,]') | str('.')).repeat(1)
        end

        def empty_line
          str("\n")
        end

        def digit
          match('[0-9]')
        end

        def digits
          match('[0-9]').repeat(1)
        end

        def word
          match('[a-zA-Z0-9_-]').repeat(1)
        end

        def words
          word >> (space? >> word).repeat
        end

        def rich_texts
          rich_text >> (space? >> rich_text).repeat
        end

        def rich_text
          (match('[a-zA-Z0-9_-]') | str('.') | str('*') | match('@')).repeat(1)
        end

        def email
          word >> str('@') >> word >> str('.') >> word
        end

        def special_character
          match('^[*:=-]') | str('[#') | str('[[')
        end

        def date
          digit.repeat(2, 4) >> str('-') >>
            digit.repeat(1, 2) >> str('-') >> digit.repeat(1, 2)
        end

        def attr_name
          match("[^\t\s]").repeat(1)
        end

        def file_path
          match('[^\[]').repeat(1)
        end

        def include_directive
          (str('include::') >>
            file_path.as(:path) >>
            attribute_list >>
          (newline | str('')).as(:line_break)
          ).as(:include)
        end

        # block_image is defined in inline.rb with full syntax
        # inline_image is defined in inline.rb for inline images (image:)

        def block_image
          (block_header >>
            match('^i') >> str('mage::') >>
            file_path.as(:path) >>
            attribute_list(:attribute_list_macro) >>
            newline.as(:line_break)
          ).as(:block_image)
        end

        # Non-capturing form of {#comment_line}. Same shape (a `//`
        # comment line, excluding tag directives like `// tag::`), but
        # consumes without producing an AST node.
        #
        # Used by list rules to absorb inter-item comments so the list
        # continues across them — asciidoctor treats `//` comments inside
        # any list as structurally invisible. Uses raw character matchers
        # instead of `text` so no inner captures leak into the consuming
        # rule's AST.
        #
        # Single source of truth for the comment-line shape: any future
        # adjustment to the `//`-line grammar happens here and both the
        # capturing and non-capturing forms stay in sync.
        def comment_line_content
          tag.absent? >>
            str('//') >> str('/').absent? >>
            space? >>
            match('[^\n]').repeat(0) >> line_ending
        end

        def comment_line
          tag.absent? >>
            (str('//') >> str('/').absent? >>
              space? >>
              text.maybe.as(:comment_text) >>
              line_ending.as(:line_break)
            ).as(:comment_line)
        end

        def tag
          (str('//') >> str('/').absent? >>
            space? >>
            (str('tag') | str('end')).as(:prefix) >>
            str('::') >> str(':').absent? >>
            match('[^\[]').repeat(1).as(:name) >>
            attribute_list >>
            line_ending.maybe.as(:line_break)
          ).as(:tag)
        end

        def comment_block
          (str('////') >> line_ending >>
          ((line_ending >> str('////')).absent? >> any
          ).repeat.as(:comment_text) >>
          line_ending >> str('////')
          ).as(:comment_block)
        end
      end
    end
  end
end
