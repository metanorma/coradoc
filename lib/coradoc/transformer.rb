require "parslet"
require "coradoc/document/title"
require "coradoc/document/block"
require "coradoc/document/section"
require "coradoc/document/attribute"
require "coradoc/document/admonition"
require "coradoc/document/text_element"

require "coradoc/document/author"
require "coradoc/document/revision"
require "coradoc/document/header"

module Coradoc
  class Transformer < Parslet::Transform
    # Header
    rule(
      title: simple(:title),
      author: simple(:author),
      revision: simple(:revision)) do
      Document::Header.new(title, author: author, revision: revision)
    end

    # Author
    rule(
      first_name: simple(:first_name),
      last_name: simple(:last_name),
      email: simple(:email)) do
      Document::Author.new(first_name, last_name, email)
    end

    # Revision
    rule(number: simple(:number), date: simple(:date), remark: simple(:remark)) do
      Document::Revision.new(number, date: date, remark: remark)
    end

    # Text Element
    rule(text: simple(:text), break: simple(:line_break)) do
      Document::TextElement.new(text, line_break: line_break)
    end

    # Title Element
    rule(
      level: simple(:level),
      text: simple(:text),
      break: simple(:line_break)) do
        Document::Title.new(text, level, line_break: line_break)
    end

    rule(
      name: simple(:name),
      level: simple(:level),
      text: simple(:text),
      break: simple(:line_break)) do
        Document::Title.new(text, level, line_break: line_break, id: name)
      end

    # Section
    rule(title: simple(:title)) { Document::Section.new(title) }

    rule(title: simple(:title), paragraphs: sequence(:paragraphs)) do
      Document::Section.new(title, paragraphs: paragraphs)
    end

    rule(title: simple(:title), blocks: sequence(:blocks)) do
      Document::Section.new(title, blocks: blocks)
    end

    # Admonition
    rule(admonition: simple(:admonition)) { admonition }
    rule(type: simple(:type), text: simple(:text), break: simple(:line_break)) do
      Document::Admonition.new(text, type.to_s, line_break: line_break)
    end

    # Block
    rule(title: simple(:title), lines: sequence(:lines)) do
      Document::Block.new(title, lines: lines)
    end

    rule(
      title: simple(:title),
      delimiter: simple(:delimiter),
      lines: sequence(:lines)) do
        Document::Block.new(title, lines: lines, delimiter: delimiter)
      end

    rule(
      type: simple(:type),
      title: simple(:title),
      delimiter: simple(:delimiter),
      lines: sequence(:lines)) do
        Document::Block.new(title, lines: lines, delimiter: delimiter, type: type)
      end

    rule(attributes: simple(:attributes), lines: sequence(:lines)) do
      Document::Block.new(nil, lines: lines, attributes: attributes)
    end

    # Attribute
    rule(key: simple(:key), value: simple(:value)) do
      Document::Attribute.new(key, value)
    end

    def self.transform(syntax_tree)
      new.apply(syntax_tree)
    end
  end
end
