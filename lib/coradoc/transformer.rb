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
      Element::Header.new(title:, author:, revision:)
    end

    # Author
    rule(
      first_name: simple(:first_name),
      last_name: simple(:last_name),
      email: simple(:email),
    ) do
      Element::Author.new(
        first_name:,
        last_name:,
        email:,
        middle_name: nil,
      )
    end

    # Revision
    rule(number: simple(:number), date: simple(:date),
         remark: simple(:remark)) do
      Element::Revision.new(number:, date:, remark:)
    end

    # Comments
    rule(comment_line: { comment_text: simple(:comment_text) }) do
      Element::CommentLine.new(text: comment_text)
    end

    rule(comment_block: { comment_text: simple(:comment_text) }) do
      Element::CommentBlock.new(text: comment_text)
    end

    rule(tag: subtree(:tag)) do
      Element::Tag.new(
        name: tag[:name],
        attrs: tag[:attribute_list],
        line_break: tag[:line_break],
        prefix: tag[:prefix],
      )
    end

    # AttributeList
    rule(named: { named_key: simple(:key),
                  named_value: simple(:value) }) do
      Element::Attribute.new(key: key.to_s, value: value.to_s)
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
        elsif a.is_a?(Element::Attribute)
          attr_list.add_named(a.key, a.value)
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
      # TODO: spec did not catch this
      Element::Include.new(
        path: path.to_s,
        attributes: attribute_list,
        line_break: line_break,
      )
    end

    # Audio
    rule(audio: {
           path: simple(:path),
           attribute_list: simple(:attribute_list),
           line_break: simple(:line_break),
         }) do
      # TODO: spec did not catch this
      Element::Audio.new(
        src: path.to_s,
        attributes: attribute_list,
        line_break: line_break,
      )
    end

    # Video
    rule(video: {
           path: simple(:path),
           attribute_list: simple(:attribute_list),
           line_break: simple(:line_break),
         }) do
      # TODO: spec did not catch this
      Element::Video.new(
        src: path.to_s,
        attributes: attribute_list,
        line_break: line_break,
      )
    end

    # Text Model
    rule(text: simple(:text)) do
      Element::TextElement.new(content: text.to_s)
    end

    rule(text_string: subtree(:text_string)) do
      text_string.to_s
    end

    rule(text: simple(:text), line_break: simple(:line_break)) do
      Element::TextElement.new(content: text.to_s, line_break: line_break)
    end

    rule(text: sequence(:text), line_break: simple(:line_break)) do
      Element::TextElement.new(content: text, line_break: line_break)
    end

    rule(id: simple(:id), text: simple(:text)) do
      Element::TextElement.new(content: text.to_s, id: id.to_s)
    end

    rule(text: sequence(:text)) do
      Element::TextElement.new(content: text)
    end

    rule(
      text: simple(:text),
      line_break: simple(:line_break),
    ) do
      Element::TextElement.new(
        content: text.to_s,
        line_break: line_break,
      )
    end

    rule(
      id: simple(:id),
      text: simple(:text),
      line_break: simple(:line_break),
    ) do
      Element::TextElement.new(
        content: text.to_s,
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
        content: text,
        id: id.to_s,
        line_break: line_break,
      )
    end

    rule(text: sequence(:text),
         line_break: simple(:line_break)) do
      Element::TextElement.new(
        content: text,
        line_break: line_break,
      )
    end

    # Inlines
    rule(href: simple(:href)) do
      Element::Inline::CrossReference.new(
        href: href.to_s,
      )
    end

    rule(href: simple(:href),
         name: simple(:name)) do
      Element::Inline::CrossReference.new(
        href: href.to_s,
        args: [name.to_s],
      )
    end

    rule(inline_image: subtree(:inline_image)) do
      Element::Image::InlineImage.new(
        title: inline_image[:text],
        src: inline_image[:path],
        attributes: inline_image[:attribute_list],
      )
    end

    rule(bold_constrained: sequence(:text)) do
      Element::Inline::Bold.new(content: text, unconstrained: false)
    end

    rule(bold_unconstrained: sequence(:text)) do
      Element::Inline::Bold.new(content: text, unconstrained: true)
    end

    rule(span_constrained: subtree(:span_constrained)) do
      Element::Inline::Span.new(text: span_constrained[:text],
                                unconstrained: false,
                                attributes: span_constrained[:attribute_list])
    end
    rule(span_unconstrained: subtree(:span_unconstrained)) do
      Element::Inline::Span.new(
        content: span_unconstrained[:text],
        unconstrained: true,
        attributes: span_unconstrained[:attribute_list],
      )
    end

    rule(italic_constrained: sequence(:text)) do
      Element::Inline::Italic.new(content: text, unconstrained: false)
    end
    rule(italic_unconstrained: sequence(:text)) do
      Element::Inline::Italic.new(content: text, unconstrained: true)
    end

    rule(highlight_constrained: sequence(:text)) do
      Element::Inline::Highlight.new(content: text, unconstrained: false)
    end
    rule(highlight_unconstrained: sequence(:text)) do
      Element::Inline::Highlight.new(content: text, unconstrained: true)
    end

    rule(monospace_constrained: sequence(:text)) do
      Element::Inline::Monospace.new(content: text, unconstrained: false)
    end
    rule(monospace_unconstrained: sequence(:text)) do
      Element::Inline::Monospace.new(content: text, unconstrained: true)
    end

    rule(superscript: sequence(:content)) do
      Element::Inline::Superscript.new(content:)
    end

    rule(subscript: sequence(:content)) do
      Element::Inline::Subscript.new(content:)
    end

    # Paragraph
    rule(paragraph: subtree(:paragraph)) do
      Element::Paragraph.new(
        content: paragraph[:lines],
        id: paragraph[:id],
        attributes: paragraph[:attribute_list],
        title: paragraph[:title],
      )
    end

    # Title Model
    rule(
      level: simple(:level),
      text: simple(:text),
      line_break: simple(:line_break),
    ) do
      Element::Title.new(content: text, level: level.size - 1,
                         line_break: line_break)
    end

    rule(
      name: simple(:name),
      level: simple(:level),
      text: simple(:text),
      line_break: simple(:line_break),
    ) do
      Element::Title.new(
        content: text,
        level: level.size - 1,
        line_break: line_break,
        id: name,
      )
    end

    # Section
    rule(section: subtree(:section)) do
      id = section[:id] || nil
      title = section[:title] || nil
      attribute_list = section[:attribute_list] || nil
      contents = section[:contents] || []
      sections = section[:sections]
      opts = { id:, attribute_list:, contents:, sections: }
      Element::Section.new(
        title: title,
        id: id,
        attribute_list: attribute_list,
        contents: contents,
        sections: sections,
      )
    end

    rule(example: sequence(:example)) do
      # TODO: spec did not catch this
      Element::Block::Core.new(title: "", type: "example", lines: example)
    end

    rule(bibliography_entry: subtree(:bib_entry)) do
      # TODO: spec did not catch this
      anchor_name = bib_entry[:anchor_name]
      document_id = bib_entry[:document_id]
      ref_text = bib_entry[:ref_text]
      line_break = bib_entry[:line_break]
      Element::BibliographyEntry.new(
        anchor_name:, document_id:, ref_text:, line_break:,
      )
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
      Element::Inline::CrossReferenceArg.new(key:, delimiter:, value:)
    end

    rule(href_arg: simple(:href_arg)) do
      href_arg.to_s
    end

    rule(cross_reference: sequence(:xref)) do
      args = xref.size > 1 ? xref[1..] : []
      Element::Inline::CrossReference.new(href: xref[0], args:)
    end

    rule(attribute_reference: simple(:name)) do
      Element::Inline::AttributeReference.new(name:)
    end

    rule(term_type: simple(:term_type),
         term: simple(:term)) do
      Coradoc::Element::Term.new(term:, type: term_type, lang: :en)
    end

    rule(footnote: simple(:footnote)) do
      Coradoc::Element::Inline::Footnote.new(text: footnote)
    end

    rule(footnote: simple(:footnote), id: simple(:id)) do
      Coradoc::Element::Inline::Footnote.new(text: footnote, id:)
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
      # TODO: spec did not catch these
      opts[:attributes] = attribute_list if attribute_list
      delimiter_len = opts[:delimiter_len]
      if delimiter_c == "*"
        if attribute_list
          if attribute_list.positional == [] &&
              attribute_list.named.keys[0] == "reviewer"
            Element::Block::ReviewerComment.new(
              id:,
              title:,
              lines:,
              delimiter_len:,
            )
          # XXX: redundant branch?
          # elsif attribute_list.positional[0] == "sidebar" &&
          #     attribute_list.named == {}
          #   Model::Block::Side.new(
          #     id:,
          #     title:,
          #     lines:,
          #     delimiter_len:,
          #   )
          else
            Element::Block::Side.new(
              id:,
              title:,
              lines:,
              delimiter_len:,
            )
          end
        else
          Element::Block::Side.new(
            id:,
            title:,
            lines:,
            delimiter_len:,
          )
        end
      elsif delimiter_c == "="
        Element::Block::Example.new(
          id:, title:, lines:, delimiter_len:,
        )
      elsif delimiter_c == "+"
        Element::Block::Pass.new(
          id:, title:, lines:, delimiter_len:,
        )
      elsif delimiter_c == "-" && delimiter.size == 2
        Element::Block::Open.new(
          id:, title:, lines:, delimiter_len:,
        )
      elsif delimiter_c == "-" && delimiter.size >= 4
        Element::Block::SourceCode.new(
          id:, title:, lines:, delimiter_len:,
        )
      elsif delimiter_c == "_"
        Element::Block::Quote.new(
          id:, title:, lines:, delimiter_len:,
        )
      end
    end

    # Admonition
    rule(admonition_type: simple(:admonition_type),
         content: sequence(:content)) do
      Element::Admonition.new(content: content, type: admonition_type.to_s)
    end

    rule(block_image: subtree(:block_image)) do
      id = block_image[:id]
      title = block_image[:title]
      path = block_image[:path]
      Element::Image::BlockImage.new(
        title: title,
        id: id,
        src: path,
        attributes: attributes,
        line_break: line_break,
      )
    end

    # Attribute
    rule(key: simple(:key), value: simple(:value), line_break: simple(:line_break)) do
      Element::Attribute.new(key:, value:, line_break:)
    end

    rule(key: simple(:key), value: simple(:value),
         line_break: simple(:line_break)) do
      Element::Attribute.new(
        key: key.to_s,
        value: value.to_s,
        line_break: line_break.to_s,
      )
    end

    rule(line_break: simple(:line_break)) do
      Element::LineBreak.new(line_break:)
    end

    rule(document_attributes: sequence(:document_attribute)) do
      Element::DocumentAttributes.new(data: document_attribute)
    end

    # Table

    rule(cols: sequence(:cols)) do
      columns = cols.map { |content| Element::Table::Cell.new(content: content) }
      Element::Table::Row.new(columns: columns)
    end

    rule(table: subtree(:table)) do
      title = table[:title] || nil
      rows = table[:rows] || []
      opts = {
        id: table[:id] || nil,
        attributes: table[:attribute_list] || nil,
      }
      Element::Table.new(title: title, rows: rows, id: opts[:id],
                         attributes: opts[:attributes])
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
        content: text, id:, marker:, attached:, nested:, line_break:,
      )
    end

    # List
    rule(list: simple(:list)) { list }
    rule(unordered: sequence(:list_items)) do
      Element::List::Unordered.new(items: list_items)
    end
    rule(attribute_list: simple(:attribute_list),
         unordered: sequence(:list_items)) do
      Element::List::Unordered.new(items: list_items, attrs: attribute_list)
    end

    rule(ordered: sequence(:list_items)) do
      Element::List::Ordered.new(items: list_items)
    end

    rule(attribute_list: simple(:attribute_list),
         ordered: sequence(:list_items)) do
      Element::List::Ordered.new(items: list_items, attrs: attribute_list)
    end

    rule(dlist_term: simple(:t),
         delimiter: simple(:d)) do
      # DefinitionListTerm.new(t.to_s, d.to_s)
      t.to_s
    end

    rule(definition_list_item: { terms: sequence(:terms),
                                 definition: simple(:contents) }) do
      Element::ListItemDefinition.new(terms: terms, contents: contents)
    end

    rule(definition_list: sequence(:list_items)) do
      Element::List::Definition.new(items: list_items)
    end

    # Highlight
    # TODO: spec did not catch this
    rule(highlight: simple(:text)) { Element::Highlight.new(content: text) }

    # Glossaries
    # TODO: spec did not catch this
    rule(glossaries: sequence(:glossaries)) do
      Element::Glossaries.new(items: glossaries)
    end

    rule(header: simple(:header)) { header }
    rule(section: simple(:section)) { section }

    rule(document: sequence(:elements)) do
      Coradoc::Document.from_ast(elements)
    end

    # rule(unparsed: simple(:text)) do
    #   text.to_s
    # end

    def self.transform(syntax_tree)
      result = new.apply(syntax_tree)
      # pp syntax_tree.inspect[0..100]
      result
    end
  end
end
