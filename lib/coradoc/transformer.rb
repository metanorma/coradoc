require "parslet"
require "coradoc/document"

module Coradoc
  class Transformer < Parslet::Transform
    # Header
    rule(
      title: simple(:title),
      author: simple(:author),
      revision: simple(:revision),
    ) do
      Element::Header.new(title, author: author, revision: revision)
    end

    # Author
    rule(
      first_name: simple(:first_name),
      last_name: simple(:last_name),
      email: simple(:email),
    ) do
      Element::Author.new(first_name, last_name, email)
    end

    # Revision
    rule(number: simple(:number), date: simple(:date),
         remark: simple(:remark)) do
      Element::Revision.new(number, date: date, remark: remark)
    end

    # Comments
    rule(comment_line: {comment_text: simple(:comment_text)}) {
      Element::Comment::Line.new(comment_text)
    }

    rule(comment_block: {comment_text: simple(:comment_text)}) {
      Element::Comment::Block.new(comment_text)
    }

    # AttributeList
    class NamedAttribute < Struct.new(:key, :value); end

    rule(:named => {named_key: simple(:key),
      named_value: simple(:value)} ) {
      NamedAttribute.new(key.to_s, value.to_s)
    }

    rule(positional: simple(:positional)){
      positional.to_s
    }

    rule(attribute_array: nil){
      Element::AttributeList.new
    }

    rule(attribute_array: sequence(:attributes)){
      attr_list = Element::AttributeList.new
      attributes.each do |a|
        if a.is_a?(String)
          attr_list.add_positional(a)
        elsif a.is_a?(NamedAttribute)
          attr_list.add_named(a[:key], a[:value])
        end
      end
      attr_list
    }

    # Include
    rule(include: {
      path: simple(:path),
      attribute_list: simple(:attribute_list),
      line_break: simple(:line_break)}
    ) {
      Element::Include.new(
        path.to_s,
        attributes: attribute_list,
        line_break: line_break)
    }


    # Text Element
    rule(text: simple(:text)) {
      Element::TextElement.new(text.to_s)
    }

    rule(text: simple(:text), line_break: simple(:line_break)) {
      Element::TextElement.new(text.to_s, line_break: line_break)
    }

    rule(id: simple(:id), text: simple(:text)) do
      Element::TextElement.new(text.to_s, id: id.to_s)
    end

    rule(text: sequence(:text)) {
      Element::TextElement.new(text)
    }

    rule(
      text: simple(:text),
      line_break: simple(:line_break)
    ) do
      Element::TextElement.new(
        text.to_s,
        line_break: line_break)
    end

    rule(
      id: simple(:id),
      text: simple(:text),
      break: simple(:line_break)
    ) do
      Element::TextElement.new(
        text.to_s,
        id: id,
        line_break: line_break)
    end

    rule(
      id: simple(:id),
      text: sequence(:text),
      break: simple(:line_break)
    ) do
      Element::TextElement.new(
        text,
        id: id,
        line_break: line_break)
    end




    rule(text: sequence(:text),
      break: simple(:line_break)
    ) do
      Element::TextElement.new(
        text,
        line_break: line_break)
    end

    # rule(text_unformatted: simple(:text)) { text }
    # rule(text: sequence({text_unformatted: simple(:t)})) { t.to_s }



    rule(href: simple(:href)){
      Element::Inline::CrossReference.new(
        href.to_s
      )
    }

    rule(href: simple(:href),
      name: simple(:name)
    ){
      Element::Inline::CrossReference.new(
        href.to_s,
        name.to_s
      )
    }

    rule(bold_constrained: {
      content: simple(:text)
    }){
      Element::Inline::Bold.new(text, unconstrained: false)
    }

    rule(bold_unconstrained: {content: simple(:text)}) {
      Element::Inline::Bold.new(text, unconstrained: true)
    }

    rule(highlight_constrained: {content: simple(:text)}) {
      Element::Inline::Highlight.new(text, unconstrained: false)
    }
    rule(highlight_unconstrained: {content: simple(:text)}) {
      Element::Inline::Highlight.new(text, unconstrained: true)
    }

    rule(italic_constrained: {content: simple(:text)}) {
      Element::Inline::Italic.new(text, unconstrained: false)
    }
    rule(italic_unconstrained: {content: simple(:text)}) {
      Element::Inline::Italic.new(text, unconstrained: true)
    }


    # Paragraph
    rule(paragraph: subtree(:paragraph)) do
      Element::Paragraph.new(
        paragraph[:lines],
        meta: paragraph[:attribute_list],
        title: paragraph[:title]
        )
    end



    # Title Element
    rule(
      level: simple(:level),
      text: simple(:text),
      line_break: simple(:line_break),
    ) do
      Element::Title.new(text, level.to_s, line_break: line_break)
    end

    rule(
      name: simple(:name),
      level: simple(:level),
      text: simple(:text),
      line_break: simple(:line_break),
    ) do
      Element::Title.new(text, level, line_break: line_break, id: name)
    end

    # Section
    # rule(title: simple(:title)) { Element::Section.new(title) }
    #
    # rule(id: simple(:id), title: simple(:title), content:)

    rule(
      title: simple(:title),
      sections: sequence(:sections),
    ) do
      Element::Section.new(title, sections: sections)
    end

    rule(
      id: simple(:id),
      title: simple(:title),
      sections: sequence(:sections),
    ) do
      Element::Section.new(title, id: id, sections: sections)
    end

    rule(
      id: simple(:id),
      title: simple(:title),
      contents: sequence(:contents),
    ) do
      Element::Section.new(title, id: id, contents: contents)
    end


    rule(
      title: simple(:title),
      contents: sequence(:contents),
      sections: sequence(:sections),
    ) do
      Element::Section.new(
        title,
        contents: contents,
        sections: sections)
    end

    rule(
      id: simple(:id),
      title: simple(:title),
      contents: sequence(:contents),
      sections: simple(:sections),
    ) do
      Element::Section.new(title, id: id, contents: contents,
                                  sections: sections)
    end

    rule(
      id: simple(:id),
      title: simple(:title),
      contents: sequence(:contents),
      sections: sequence(:sections),
    ) do
      Element::Section.new(title, id: id, contents: contents,
                                  sections: sections)
    end

    rule(
      title: simple(:title),
      contents: sequence(:contents),
      sections: simple(:sections),
    ) do
      Element::Section.new(title, contents: contents,
                                  sections: sections)
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

    rule(bibliography_entry: subtree(:bib_entry) ){
      Element::BibliographyEntry.new(bib_entry)
    }

    rule( #bibliography: subtree(:bib_data)){
      id: simple(:id),
      title: simple(:title),
      entries: sequence(:entries)
    ){
      Element::Bibliography.new(
        # bib_data
        id: id,
        title: title,
        entries: entries
        )
    }

    rule(block: {
      delimiter: simple(:delimiter),
      lines: sequence(:lines)
    }) {
      if delimiter == "****"
        Element::Block::Side.new(
          title: nil,
          lines: lines
        )
      end
    }

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

    rule(key: simple(:key), value: simple(:value),
         break: simple(:line_break)) do
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

    # rule(list: simple(:list)) { list }
    rule(ordered: sequence(:list_items)) do
      Element::List::Ordered.new(list_items)
    end



    rule(terms: simple(:terms), definition: simple(:definition)) do
      Element::ListItemDefinition.new(terms, contents)
    end

    rule(definition_list: sequence(:definition_list)) do
      Element::List::Definition.new(list_items)
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


    # rule(unparsed: simple(:text)) do
    #   text.to_s
    # end

    def self.transform(syntax_tree)
      new.apply(syntax_tree)
    end
  end
end
