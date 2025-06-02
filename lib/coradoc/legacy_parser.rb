require "parslet"
require "parslet/convenience"

module Coradoc
  class LegacyParser < Parslet::Parser
    root :document

    # Basic Elements
    rule(:space) do
      match('\s')
    end
    rule(:space?) do
      spaces.maybe
    end
    rule(:spaces) do
      space.repeat(1)
    end
    rule(:empty_line) do
      match("^\n")
    end

    rule(:endline) do
      newline | any.absent?
    end
    rule(:newline) do
      match["\r\n"].repeat(1)
    end
    rule(:line_ending) do
      match("[\n]")
    end

    rule(:inline_element) do
      text
    end
    rule(:text) do
      match("[^\n]").repeat(1)
    end
    rule(:digits) do
      match("[0-9]").repeat(1)
    end
    rule(:word) do
      match("[a-zA-Z0-9_-]").repeat(1)
    end
    rule(:special_character) do
      match("^[*_:=-]") | str("[#")
    end

    rule(:text_line) do
      special_character.absent? >>
        match("[^\n]").repeat(1).as(:text) >>
        line_ending.as(:break)
    end

    # Common Helpers
    rule(:words) do
      word >> (space? >> word).repeat
    end
    rule(:email) do
      word >> str("@") >> word >> str(".") >> word
    end

    # Document
    rule(:document) do
      (
        document_attributes.repeat(1).as(:document_attributes) |
        section.as(:section) |
        header.as(:header) |
        block_with_title.as(:block) |
        empty_line.repeat(1) |
        any.as(:unparsed)
      ).repeat(1).as(:document)
    end

    # Header
    rule(:header) do
      match("=") >> space? >> text.as(:title) >> newline >>
        author.maybe.as(:author) >> revision.maybe.as(:revision)
    end

    rule(:author) do
      words.as(:first_name) >> str(",") >> space? >> words.as(:last_name) >>
        space? >> str("<") >> email.as(:email) >> str(">") >> endline
    end

    rule(:revision) do
      (word >> (str(".") >> word).maybe).as(:number) >>
        str(",") >> space? >> word.as(:date) >>
        str(":") >> space? >> words.as(:remark) >> newline
    end

    # DocumentAttributes
    rule(:document_attributes) do
      str(":") >> attribute_name.as(:key) >> str(":") >>
        space? >> attribute_value.as(:value) >> endline
    end

    # Section
    rule(:section) do
      heading.as(:title) >>
        (list.as(:list) | blocks.as(:blocks) | paragraphs.as(:paragraphs)).maybe
    end

    # Heading
    rule(:heading) do
      (anchor_name >> newline).maybe >>
        match("=").repeat(2, 8).as(:level) >>
        space? >> text.as(:text) >> endline.as(:break)
    end

    rule(:anchor_name) do
      str("[#") >> keyword.as(:name) >> str("]")
    end

    # List
    rule(:list) do
      unordered_list.as(:unordered) |
        definition_list.as(:definition) | ordered_list.as(:ordered)
    end

    rule(:ordered_list) do
      olist_item.repeat(1)
    end
    rule(:unordered_list) do
      ulist_item.repeat(1)
    end
    rule(:definition_list) do
      dlist_item.repeat(1)
    end

    rule(:olist_item) do
      match(".") >> space >> text_line
    end
    rule(:ulist_item) do
      match("\\*") >> space >> text_line
    end
    rule(:dlist_item) do
      str("term") >> space >> digits >> str("::") >> space >> text_line
    end

    # Block
    rule(:block) do
      simple_block | open_block
    end
    rule(:attribute_name) do
      keyword
    end
    rule(:attribute_value) do
      text | str("")
    end
    rule(:keyword) do
      match("[a-zA-Z0-9_-]").repeat(1)
    end
    rule(:blocks) do
      block.repeat(1) >> (newline >> block.repeat(1)).maybe
    end

    rule(:block_title) do
      str(".") >> text.as(:title) >> line_ending
    end
    rule(:block_type) do
      str("[") >> keyword.as(:type) >> str("]") >> newline
    end

    rule(:block_attribute) do
      str("[") >> keyword.as(:key) >> str("=") >> keyword.as(:value) >> str("]")
    end

    rule(:simple_block) do
      block_attribute.as(:attributes) >> newline >>
        text_line.repeat(1).as(:lines)
    end

    rule(:open_block) do
      block_title >>
        block_type >>
        str("--").as(:delimiter) >> newline >>
        text_line.repeat.as(:lines) >>
        str("--") >> line_ending
    end

    rule(:example_block) do
      block_title >>
        block_type >>
        str("====").as(:delimiter) >> newline >>
        text_line.repeat(1).as(:lines) >>
        str("====") >> newline
    end

    rule(:sidebar_block) do
      block_title >>
        block_type.maybe >>
        str("****").as(:delimiter) >> newline >>
        text_line.repeat(1).as(:lines) >>
        str("****") >> newline
    end

    rule(:source_block) do
      block_title >>
        str("----").as(:delimiter) >> newline >>
        text_line.repeat(1).as(:lines) >>
        str("----") >> newline
    end

    rule(:quote_block) do
      block_title >>
        str("____").as(:delimiter) >> newline >>
        text_line.repeat.as(:lines) >>
        str("____") >> newline
    end

    rule(:block_with_title) do
      example_block | quote_block |
        sidebar_block | source_block | open_block |
        (block_title >> text_line.repeat(1).as(:lines))
    end

    # Paragraph
    rule(:paragraphs) do
      paragraph >> (line_ending.repeat(1) >> paragraph).repeat.maybe
    end

    rule(:paragraph) do
      admonitions.repeat(1) | text_line.repeat(1)
    end

    # Admonition
    rule(:admonition_type) do
      (str("NOTE") |
       str("TIP") |
       str("EDITOR") |
       str("DANGER") |
       str("CAUTION") |
       str("WARNING") |
       str("IMPORTANT")).as(:type)
    end

    rule(:admonitions) do
      admonition.as(:admonition).repeat(1)
    end
    rule(:admonition) do
      inline_admonition | block_admonition
    end

    rule(:inline_admonition) do
      admonition_type >> str(":") >> space? >> text_line >> newline
    end

    rule(:block_admonition) do
      str("[") >> admonition_type >> str("]") >> newline >> text_line >> newline
    end

    def self.parse(filename)
      content = File.read(filename)
      new.parse_with_debug(content)
    end
  end
end
