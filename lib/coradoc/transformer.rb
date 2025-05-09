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
    rule(comment_line: { comment_text: simple(:comment_text) }) do
      Element::Comment::Line.new(comment_text)
    end

    rule(comment_block: { comment_text: simple(:comment_text) }) do
      Element::Comment::Block.new(comment_text)
    end

    rule(tag: subtree(:tag)) do
      opts = {}
      opts[:prefix] = tag[:prefix]
      opts[:attribute_list] = tag[:attribute_list]
      opts[:line_break] = tag[:line_break]
      Element::Tag.new(tag[:name], opts)
    end

    # AttributeList
    NamedAttribute = Struct.new(:key, :value)

    rule(named: { named_key: simple(:key),
                  named_value: simple(:value) }) do
      NamedAttribute.new(key.to_s, value.to_s)
    end

    rule(positional: simple(:positional)) do
      positional.to_s
    end

    rule(attribute_array: nil) do
      Element::AttributeList.new
    end

    rule(attribute_array: sequence(:attributes)) do
      attr_list = Element::AttributeList.new
      attributes.each do |a|
        if a.is_a?(String)
          attr_list.add_positional(a)
        elsif a.is_a?(NamedAttribute)
          attr_list.add_named(a[:key], a[:value])
        end
      end
      attr_list
    end

    # Include
    rule(include: {
           path: simple(:path),
           attribute_list: simple(:attribute_list),
           line_break: simple(:line_break),
         }) do
      Element::Include.new(
        path.to_s,
        attributes: attribute_list,
        line_break: line_break,
      )
    end

    # Text Element
    rule(text: simple(:text)) do
      Element::TextElement.new(text.to_s)
    end

    rule(text_string: subtree(:text_string)) do
      text_string.to_s
    end

    rule(text: simple(:text), line_break: simple(:line_break)) do
      Element::TextElement.new(text.to_s, line_break: line_break)
    end

    rule(text: sequence(:text), line_break: simple(:line_break)) do
      Element::TextElement.new(text, line_break: line_break)
    end

    rule(id: simple(:id), text: simple(:text)) do
      Element::TextElement.new(text.to_s, id: id.to_s)
    end

    rule(text: sequence(:text)) do
      Element::TextElement.new(text)
    end

    rule(
      text: simple(:text),
      line_break: simple(:line_break),
    ) do
      Element::TextElement.new(
        text.to_s,
        line_break: line_break,
      )
    end

    rule(
      id: simple(:id),
      text: simple(:text),
      line_break: simple(:line_break),
    ) do
      Element::TextElement.new(
        text.to_s,
        id: id.to_s,
        line_break: line_break,
      )
    end

    rule(
      id: simple(:id),
      text: sequence(:text),
      line_break: simple(:line_break),
    ) do
      Element::TextElement.new(
        text,
        id: id.to_s,
        line_break: line_break,
      )
    end

    rule(text: sequence(:text),
         line_break: simple(:line_break)) do
      Element::TextElement.new(
        text,
        line_break: line_break,
      )
    end

    # Inlines
    rule(href: simple(:href)) do
      Element::Inline::CrossReference.new(
        href.to_s,
      )
    end

    rule(href: simple(:href),
         name: simple(:name)) do
      Element::Inline::CrossReference.new(
        href.to_s,
        name.to_s,
      )
    end

    rule(bold_constrained: sequence(:text)) do
      Element::Inline::Bold.new(text, unconstrained: false)
    end

    rule(bold_unconstrained: sequence(:text)) do
      Element::Inline::Bold.new(text, unconstrained: true)
    end

    rule(span_constrained: subtree(:span_constrained)) do
      Element::Inline::Span.new(span_constrained[:text],
                                unconstrained: false,
                                attributes: span_constrained[:attribute_list])
    end
    rule(span_unconstrained: subtree(:span_unconstrained)) do
      Element::Inline::Span.new(span_unconstrained[:text], unconstrained: true,
                                                           attributes: span_unconstrained[:attribute_list])
    end

    rule(italic_constrained: sequence(:text)) do
      Element::Inline::Italic.new(text, unconstrained: false)
    end
    rule(italic_unconstrained: sequence(:text)) do
      Element::Inline::Italic.new(text, unconstrained: true)
    end

    rule(highlight_constrained: sequence(:text)) do
      Element::Inline::Highlight.new(text, unconstrained: false)
    end
    rule(highlight_unconstrained: sequence(:text)) do
      Element::Inline::Highlight.new(text, unconstrained: true)
    end

    rule(monospace_constrained: sequence(:text)) do
      Element::Inline::Monospace.new(text, unconstrained: false)
    end
    rule(monospace_unconstrained: sequence(:text)) do
      Element::Inline::Monospace.new(text, unconstrained: true)
    end

    rule(superscript: sequence(:content)) do
      Element::Inline::Superscript.new(content)
    end

    rule(subscript: sequence(:content)) do
      Element::Inline::Subscript.new(content)
    end

    # Paragraph
    rule(paragraph: subtree(:paragraph)) do
      Element::Paragraph.new(
        paragraph[:lines],
        id: paragraph[:id],
        attributes: paragraph[:attribute_list],
        title: paragraph[:title],
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
      opts = { id:, attribute_list:, contents:, sections: }
      Element::Section.new(title, opts)
    end

    rule(example: sequence(:example)) do
      Element::Core.new("", type: "example", lines: example)
    end

    rule(bibliography_entry: subtree(:bib_entry)) do
      Element::BibliographyEntry.new(bib_entry)
    end

    rule(
      id: simple(:id),
      title: simple(:title),
      entries: sequence(:entries),
    ) do
      Element::Bibliography.new(
        id: id,
        title: title,
        entries: entries,
      )
    end

    rule(
      key: simple(:key),
      delimiter: simple(:delimiter),
      value: simple(:value),
    ) do
      Element::Inline::CrossReferenceArg.new(key, delimiter, value)
    end

    rule(href_arg: simple(:href_arg)) do
      href_arg.to_s
    end

    rule(cross_reference: sequence(:xref)) do
      args = xref.size > 1 ? xref[1..] : []
      Element::Inline::CrossReference.new(xref[0], args)
    end

    rule(attribute_reference: simple(:name)) do
      Element::Inline::AttributeReference.new(name)
    end

    rule(term_type: simple(:term_type),
         term: simple(:term)) do
      Coradoc::Element::Term.new(term, type: term_type, lang: :en)
    end

    rule(footnote: simple(:footnote)) do
      Coradoc::Element::Inline::Footnote.new(footnote)
    end

    rule(footnote: simple(:footnote), id: simple(:id)) do
      Coradoc::Element::Inline::Footnote.new(footnote, id)
    end

    rule(block: subtree(:block)) do
      id = block[:id]
      title = block[:title]
      attribute_list = block[:attribute_list]
      delimiter = block[:delimiter].to_s
      delimiter_c = delimiter[0]
      lines = block[:lines]
      ordering = block.keys.select do |k|
        %i[id title attribute_list attribute_list2].include?(k)
      end

      opts = { id: id,
               title: title,
               delimiter_len: delimiter.size,
               lines: lines,
               ordering: ordering }
      opts[:attributes] = attribute_list if attribute_list
      if delimiter_c == "*"
        if attribute_list
          if attribute_list.positional == [] &&
              attribute_list.named.keys[0] == "reviewer"
            Element::Block::ReviewerComment.new(opts)
          elsif attribute_list.positional[0] == "sidebar" &&
              attribute_list.named == {}
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
      elsif delimiter_c == "-" && delimiter.size >= 4
        Element::Block::SourceCode.new(title, opts)
      elsif delimiter_c == "_"
        Element::Block::Quote.new(title, opts)
      end
    end

    # Admonition
    rule(admonition_type: simple(:admonition_type),
         content: sequence(:content)) do
      Element::Admonition.new(content, admonition_type.to_s)
    end

    rule(block_image: subtree(:block_image)) do
      id = block_image[:id]
      title = block_image[:title]
      path = block_image[:path]
      opts = {
        attributes: block_image[:attribute_list_macro],
        line_break: block_image[:line_break],
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

    rule(line_break: simple(:line_break)) do
      Element::LineBreak.new(line_break)
    end

    rule(document_attributes: sequence(:document_attributes)) do
      Element::DocumentAttributes.new(document_attributes)
    end

    # Table

    rule(cols: sequence(:cols)) do
      cells = cols.map { |c| Element::Table::Cell.new(content: c) }
      Element::Table::Row.new(cells)
    end

    rule(table: subtree(:table)) do
      title = table[:title] || nil
      rows = table[:rows] || []
      opts = {
        id: table[:id] || nil,
        attributes: table[:attribute_list] || nil,
      }
      Element::Table.new(title, rows, opts)
    end

    rule(list_item: subtree(:list_item)) do
      marker = list_item[:marker]
      id = list_item[:id]
      text = list_item[:text]
      text = list_item[:text].to_s if list_item[:text].instance_of?(Parslet::Slice)
      attached = list_item[:attached]
      nested = list_item[:nested]
      line_break = list_item[:line_break]
      Element::ListItem.new(
        text, id:, marker:, attached:, nested:, line_break:
      )
    end

    # List
    rule(list: simple(:list)) { list }
    rule(unordered: sequence(:list_items)) do
      Element::List::Unordered.new(list_items)
    end
    rule(attribute_list: simple(:attribute_list),
         unordered: sequence(:list_items)) do
      Element::List::Unordered.new(list_items, attrs: attribute_list)
    end

    rule(ordered: sequence(:list_items)) do
      Element::List::Ordered.new(list_items)
    end

    rule(attribute_list: simple(:attribute_list),
         ordered: sequence(:list_items)) do
      Element::List::Ordered.new(list_items, attrs: attribute_list)
    end

    rule(dlist_term: simple(:t),
         delimiter: simple(:d)) do
      # DefinitionListTerm.new(t.to_s, d.to_s)
      t.to_s
    end

    rule(definition_list_item: { terms: sequence(:terms),
                                 definition: simple(:contents) }) do
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
