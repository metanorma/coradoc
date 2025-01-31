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

    rule(tag: subtree(:tag)) {
      opts = {}
      opts[:prefix] = tag[:prefix]
      opts[:attribute_list] = tag[:attribute_list]
      opts[:line_break] = tag[:line_break]
      Element::Tag.new(tag[:name], opts)
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

    rule(text_string: subtree(:text_string)) {
      text_string.to_s
    }

    rule(text: simple(:text), line_break: simple(:line_break)) {
      Element::TextElement.new(text.to_s, line_break: line_break)
    }

    rule(text: sequence(:text), line_break: simple(:line_break)) {
      Element::TextElement.new(text, line_break: line_break)
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
        id: id.to_s,
        line_break: line_break)
    end

    rule(
      id: simple(:id),
      text: sequence(:text),
      line_break: simple(:line_break)
    ) do
      Element::TextElement.new(
        text,
        id: id.to_s,
        line_break: line_break)
    end

    rule(text: sequence(:text),
      line_break: simple(:line_break)
    ) do
      Element::TextElement.new(
        text,
        line_break: line_break)
    end

    # Inlines
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

    rule(bold_constrained: sequence(:text)){
      Element::Inline::Bold.new(text, unconstrained: false)
    }

    rule(bold_unconstrained: sequence(:text)) {
      Element::Inline::Bold.new(text, unconstrained: true)
    }

    rule(span_constrained: subtree(:span_constrained)) {
      Element::Inline::Span.new(span_constrained[:text],
                                :unconstrained => false,
                                :attributes => span_constrained[:attribute_list])
    }
    rule(span_unconstrained: subtree(:span_unconstrained)) {
      Element::Inline::Span.new(span_unconstrained[:text], unconstrained: true,
        attributes: span_unconstrained[:attribute_list])
    }

    rule(italic_constrained: sequence(:text)) {
      Element::Inline::Italic.new(text, unconstrained: false)
    }
    rule(italic_unconstrained: sequence(:text)) {
      Element::Inline::Italic.new(text, unconstrained: true)
    }

    rule(highlight_constrained: sequence(:text)) {
      Element::Inline::Highlight.new(text, unconstrained: false)
    }
    rule(highlight_unconstrained: sequence(:text)) {
      Element::Inline::Highlight.new(text, unconstrained: true)
    }

    rule(monospace_constrained: sequence(:text)) {
      Element::Inline::Monospace.new(text, unconstrained: false)
    }
    rule(monospace_unconstrained: sequence(:text)) {
      Element::Inline::Monospace.new(text, unconstrained: true)
    }



    rule(superscript: sequence(:content)) {
      Element::Inline::Superscript.new(content)
    }

    rule(subscript: sequence(:content)) {
      Element::Inline::Subscript.new(content)
    }


    # Paragraph
    rule(paragraph: subtree(:paragraph)) do
      Element::Paragraph.new(
        paragraph[:lines],
        id: paragraph[:id],
        attributes: paragraph[:attribute_list],
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

    rule(bibliography_entry: subtree(:bib_entry) ){
      Element::BibliographyEntry.new(bib_entry)
    }

    rule(
      id: simple(:id),
      title: simple(:title),
      entries: sequence(:entries)
    ){
      Element::Bibliography.new(
        id: id,
        title: title,
        entries: entries
        )
    }

    rule(
      key: simple(:key),
      delimiter: simple(:delimiter),
      value: simple(:value)
      ){
      Element::Inline::CrossReferenceArg.new(key, delimiter, value)
    }

    rule(href_arg: simple(:href_arg)){
        href_arg.to_s
    }

    rule(cross_reference: sequence(:xref)){
        Element::Inline::CrossReference.new(xref[0], xref[1..-1])
    }


    rule(attribute_reference: simple(:name)){
        Element::Inline::AttributeReference.new(name)
    }

    rule(term_type: simple(:term_type),
      term: simple(:term)){
      Coradoc::Element::Term.new(term, type: term_type, lang: :en)
    }

    rule(footnote: simple(:footnote)){
      Coradoc::Element::Inline::Footnote.new(footnote)
    }

    rule(footnote: simple(:footnote), id: simple(:id)){
      Coradoc::Element::Inline::Footnote.new(footnote, id)
    }


    rule(block: subtree(:block)
    ) {

      id = block[:id]
      title = block[:title]
      attribute_list = block[:attribute_list]
      delimiter = block[:delimiter].to_s
      delimiter_c = delimiter[0]
      lines = block[:lines]
      ordering = block.keys.select{|k|
        [:id, :title, :attribute_list, :attribute_list2].include?(k)}

      opts = {id: id,
        title: title, 
        delimiter_len: delimiter.size,
        lines: lines,
        ordering: ordering}
      opts[:attributes] = attribute_list if attribute_list
      if delimiter_c == "*"
        if attribute_list
          if (attribute_list.positional == [] &&
           attribute_list.named.keys[0] == "reviewer")
            Element::Block::ReviewerComment.new(opts)
          elsif (attribute_list.positional[0] == "sidebar" &&
            attribute_list.named == {})
            Element::Block::Side.new(opts)
          else
            Element::Block::Side.new(opts)
          end
        else
          Element::Block::Side.new(opts)
        end
      elsif delimiter_c == "="
        Element::Block::Example.new(title, opts)
      elsif delimiter_c == "+"
        Element::Block::Pass.new(opts)
      elsif delimiter_c == "-" && delimiter.size == 2
        Element::Block::Open.new(title, opts)
      elsif delimiter_c == "-"&& delimiter.size >= 4
        Element::Block::SourceCode.new(title, opts)
      elsif delimiter_c == "_"
        Element::Block::Quote.new(title, opts)
      end
    }

    # Admonition
    rule(admonition_type: simple(:admonition_type),
      content: sequence(:content),
      ) do
      Element::Admonition.new(content, admonition_type.to_s)
    end

    rule(block_image: subtree(:block_image)) do
      id = block_image[:id]
      title = block_image[:title]
      path = block_image[:path]
      opts = {
        attributes: block_image[:attribute_list_macro],
        line_break: block_image[:line_break]
      }
      Element::Image::BlockImage.new(title, id, path, opts)
    end



    # Attribute
    rule(key: simple(:key), value: simple(:value)) do
      Element::Attribute.new(key.to_s, value.to_s)
    end

    rule(key: simple(:key), value: simple(:value),
         line_break: simple(:line_break)) do
      Element::Attribute.new(key.to_s, value.to_s, line_break: line_break.to_s)
    end

    rule(line_break: simple(:line_break)) {
      Element::LineBreak.new(line_break)
    }

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
      opts = {
        id: table[:id] || nil,
        attributes: table[:attribute_list] || nil
      }
      Element::Table.new(title, rows, opts)
    end

    rule(list_item: subtree(:list_item)) do
      marker = list_item[:marker]
      id = list_item[:id]
      text = list_item[:text]
      text = list_item[:text].to_s if list_item[:text].class == Parslet::Slice
      attached = list_item[:attached]
      nested = list_item[:nested]
      line_break = list_item[:line_break]
      Element::ListItem.new(
        text, id:, marker:, attached:, nested:, line_break: )
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

    rule(ordered: sequence(:list_items)) do
      Element::List::Ordered.new(list_items)
    end

    rule(attribute_list: simple(:attribute_list),
      ordered: sequence(:list_items)
    ) do
      Element::List::Ordered.new(list_items, attrs: attribute_list)
    end




    rule(dlist_term: simple(:t),
      delimiter: simple(:d) ) {
      # DefinitionListTerm.new(t.to_s, d.to_s)
      t.to_s
    }

    rule(definition_list_item: {terms: sequence(:terms),
                              definition: simple(:contents)}) do
      Element::ListItemDefinition.new(terms, contents)
    end

    rule(definition_list: sequence(:list_items)) do
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
