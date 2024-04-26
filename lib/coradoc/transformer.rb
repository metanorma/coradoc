require "parslet"
require "coradoc/document"

module Coradoc
  class Transformer < Parslet::Transform
    # Header
    rule(
      title: simple(:title),
      author: simple(:author),
      revision: simple(:revision)) do
      Element::Header.new(title, author: author, revision: revision)
    end

    # Author
    rule(
      first_name: simple(:first_name),
      last_name: simple(:last_name),
      email: simple(:email)) do
      Element::Author.new(first_name, last_name, email)
    end

    # Revision
    rule(number: simple(:number), date: simple(:date), remark: simple(:remark)) do
      Element::Revision.new(number, date: date, remark: remark)
    end

    # Text Element
    rule(text: simple(:text)) { Element::TextElement.new(text) }
    rule(id: simple(:id), text: simple(:text)) do
      Element::TextElement.new(text, id: id)
    end

    rule(text: simple(:text), break: simple(:line_break)) do
      Element::TextElement.new(text, line_break: line_break)
    end

    rule(id: simple(:id), text: simple(:text), break: simple(:line_break)) do
      Element::TextElement.new(text, id: id, line_break: line_break)
    end

    # Paragraph
    rule(paragraph: simple(:paragraph)) { paragraph }
    rule(lines: sequence(:lines)) { Element::Paragraph.new(lines) }
    rule(meta: simple(:meta), lines: sequence(:lines)) do
      Element::Paragraph.new(lines, meta: meta)
    end

    # Title Element
    rule(
      level: simple(:level),
      text: simple(:text),
      break: simple(:line_break)) do
        Element::Title.new(text, level, line_break: line_break)
    end

    rule(
      name: simple(:name),
      level: simple(:level),
      text: simple(:text),
      break: simple(:line_break)) do
        Element::Title.new(text, level, line_break: line_break, id: name)
    end


    # Section
    # rule(title: simple(:title)) { Element::Section.new(title) }
    #
    # rule(id: simple(:id), title: simple(:title), content:)
    rule(
      id: simple(:id),
      title: simple(:title),
      sections: sequence(:sections)) do
      Element::Section.new(title, id: id, sections: sections)
    end

    rule(
      id: simple(:id),
      title: simple(:title),
      contents: sequence(:contents),
      sections: simple(:sections)) do
      Element::Section.new(title, id: id, contents: contents, sections: sections)
    end

    rule(
      id: simple(:id),
      title: simple(:title),
      contents: sequence(:contents),
      sections: sequence(:sections)) do
        Element::Section.new(title, id: id, contents: contents, sections: sections)
    end

    rule(example: sequence(:example)) do
      Element::Core.new("", type: "example", lines: example)
    end

    # rule(title: simple(:title), paragraphs: sequence(:paragraphs)) do
    #   Element::Section.new(title, paragraphs: paragraphs)
    # end
    #
    # rule(title: simple(:title), blocks: sequence(:blocks)) do
    #   Element::Section.new(title, blocks: blocks)
    # end
    #
    # # Admonition
    # rule(admonition: simple(:admonition)) { admonition }
    # rule(type: simple(:type), text: simple(:text), break: simple(:line_break)) do
    #   Element::Admonition.new(text, type.to_s, line_break: line_break)
    # end
    #
    # # Block
    # rule(title: simple(:title), lines: sequence(:lines)) do
    #   Element::Block.new(title, lines: lines)
    # end
    #
    # rule(
    #   title: simple(:title),
    #   delimiter: simple(:delimiter),
    #   lines: sequence(:lines)) do
    #     Element::Block.new(title, lines: lines, delimiter: delimiter)
    #   end
    #
    # rule(
    #   type: simple(:type),
    #   title: simple(:title),
    #   delimiter: simple(:delimiter),
    #   lines: sequence(:lines)) do
    #     Element::Block.new(title, lines: lines, delimiter: delimiter, type: type)
    #   end
    #
    # rule(attributes: simple(:attributes), lines: sequence(:lines)) do
    #   Element::Block.new(nil, lines: lines, attributes: attributes)
    # end
    #
    # Attribute
    rule(key: simple(:key), value: simple(:value)) do
      Element::Attribute.new(key, value)
    end

    rule(key: simple(:key), value: simple(:value), break: simple(:line_break)) do
      Element::Attribute.new(key, value, line_break: line_break)
    end

    rule(line_break: simple(:line_break)) { Element::LineBreak.new(line_break) }

    rule(document_attributes: sequence(:document_attributes)) do
      Element::DocumentAttributes.new(document_attributes)
    end

    # Table
    rule(table: simple(:table)) { table }
    rule(cols: sequence(:cols)) { Element::Table::Row.new(cols) }
    rule(title: simple(:title), rows: sequence(:rows)) do
      Element::Table.new(title, rows)
    end

    # List
    rule(list: simple(:list)) { list }
    rule(unordered: sequence(:list_items)) do
      Element::List::Unordered.new(list_items)
    end

    # Highlight
    rule(highlight: simple(:text)) { Element::Highlight.new(text) }

    # Glossaries
    rule(glossaries: sequence(:glossaries)) do
      Element::Glossaries.new(glossaries)
    end

    rule(header: simple(:header)) { header }
    rule(section: simple(:section)) { section }

    rule(document: sequence(:elements)) do
      Document.from_ast(elements)
    end

    def self.transform(syntax_tree)
      new.apply(syntax_tree)
    end
  end
end
