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
      line_break: simple(:line_break)
    ) do
      Element::TextElement.new(
        text.to_s,
        id: id,
        line_break: line_break)
    end

    rule(
      id: simple(:id),
      text: sequence(:text),
      line_break: simple(:line_break)
    ) do
      Element::TextElement.new(
        text,
        id: id,
        line_break: line_break)
    end




    rule(text: sequence(:text),
      line_break: simple(:line_break)
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
      Element::Title.new(text, level.size - 1, line_break: line_break)
    end

    rule(
      name: simple(:name),
      level: simple(:level),
      text: simple(:text),
      line_break: simple(:line_break),
    ) do
      Element::Title.new(text, level.size - 1, line_break: line_break, id: name)
    end

    # Section
    # rule(title: simple(:title)) { Element::Section.new(title) }
    #
    # rule(id: simple(:id), title: simple(:title), content:)

    rule(section: subtree(:section)) do
      id = section[:id] || nil
      title = section[:title] || nil
      attribute_list = section[:attribute_list] || nil
      contents = section[:contents] || []
      sections = section[:sections]
      opts = {id:,attribute_list:,contents:,sections: }
      Element::Section.new(title, opts)
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

    rule(citation: {cross_reference: simple(:cross_reference),
      comment: simple(:comment)}){
      Element::Inline::Citation.new(cross_reference, comment)
    }

    rule(citation: {cross_reference: simple(:cross_reference)}){
      Element::Inline::Citation.new(cross_reference)
    }


    rule(block: subtree(:block)
    # {
    #     title: simple(:title),
    #   attribute_list: simple(:attribute_list),
    #   delimiter: simple(:delimiter),
    #   lines: sequence(:lines)
    # }
    ) {
      title = block[:title]
      attribute_list = block[:attribute_list]
      delimiter = block[:delimiter]
      lines = block[:lines]

      opts = {title: title, 
        attributes: attribute_list,
        delimiter_len: delimiter.size,
        lines: lines}
      if delimiter == "****"
        # puts attribute_lisp.inspect
        if (attribute_list.positional == [] &&
           attribute_list.named.keys[0] == "reviewer")
          Element::Block::ReviewerComment.new(
            opts
            )
        elsif (attribute_list.positional[0] == "sidebar" &&
          attribute_list.named == {})
          Element::Block::Side.new(
            opts
          )
        end
      elsif delimiter == "____"
        Element::Block::Quote.new
      end
    }

    # # Admonition
    # rule(admonition_type: simple(:admonition)) { admonition }
    rule(admonition_type: simple(:admonition_type),
      content: sequence(:content),
      # line_break: simple(:line_break)
      ) do
      Element::Admonition.new(content, admonition_type.to_s)
    end
    
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
         line_break: simple(:line_break)) do
      Element::Attribute.new(key, value, line_break: line_break)
    end

    rule(line_break: simple(:line_break)) { Element::LineBreak.new(line_break) }

    rule(document_attributes: sequence(:document_attributes)) do
      Element::DocumentAttributes.new(document_attributes)
    end

    # Table

    rule(cols: sequence(:cols)) {
      cells = cols.map{|c| Element::Table::Cell.new(content: c)}
      Element::Table::Row.new(cells)
    }

    rule(table: subtree(:table)) do
      title = table[:title] || nil
      rows = table[:rows] || []
      opts = {attributes: table[:attribute_list] || ""}
      Element::Table.new(title, rows, opts)
    end



    rule(list_item: simple(:list_item),
      marker: simple(:marker),
      text: simple(:text),
      line_break: simple(:line_break)) do
      Element::ListItem.new(
        text,
        marker: marker.to_s,
        line_break: line_break
        )
    end

    rule(list_item: simple(:list_item),
      marker: simple(:marker),
      id: simple(:id),
      text: simple(:text),
      line_break: simple(:line_break)) do
      Element::ListItem.new(
        text,
        id: id,
        marker: marker.to_s,
        line_break: line_break
        )
    end


    # List
    rule(list: simple(:list)) { list }
    rule(unordered: sequence(:list_items)) do
      Element::List::Unordered.new(list_items)
    end
    rule(attribute_list: simple(:attribute_list),
      unordered: sequence(:list_items)
    ) do
      Element::List::Unordered.new(list_items, attrs: attribute_list)
    end



    # rule(list: simple(:list)) { list }
    rule(ordered: sequence(:list_items)) do
      Element::List::Ordered.new(list_items)
    end

    rule(attribute_list: simple(:attribute_list),
      ordered: sequence(:list_items)
    ) do
      Element::List::Ordered.new(list_items, attrs: attribute_list)
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
