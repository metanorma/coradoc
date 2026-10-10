# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Transforms CoreModel to AsciiDoc models
      class FromCoreModel
        @registered = false

        class << self
          def register!
            return if @registered

            Transform::FromCoreModelRegistrations.register_all!
            @registered = true
          end

          def transform(model)
            register!
            return model.map { |item| transform(item) } if model.is_a?(Array)
            return model unless model.is_a?(Coradoc::CoreModel::Base)

            transformer = Registry.lookup(model.class)
            transformer ? transformer.call(model) : model
          end

          def transform_structural_element(element)
            case element
            when CoreModel::DocumentElement
              without_frontmatter, frontmatter = extract_frontmatter(Array(element.children))
              without_title_heading, title_text = extract_title_heading(without_frontmatter, element.title)

              header = if title_text
                         Coradoc::AsciiDoc::Model::Header.new(
                           title: Coradoc::AsciiDoc::Model::Title.new(
                             content: title_text,
                             level_int: 0
                           )
                         )
                       else
                         Coradoc::AsciiDoc::Model::Header.new(title: '')
                       end

              Coradoc::AsciiDoc::Model::Document.new(
                id: element.id,
                header: header,
                sections: flatten_children(without_title_heading),
                frontmatter: frontmatter
              )
            when CoreModel::SectionElement
              Coradoc::AsciiDoc::Model::Section.new(
                id: element.id,
                level: element.level,
                title: create_title(element.title, element.level),
                contents: flatten_children(element.children)
              )
            else
              Coradoc::AsciiDoc::Model::Section.new(
                id: element.id,
                title: create_title(element.title, 1),
                contents: flatten_children(element.children)
              )
            end
          end

          # Transforms each CoreModel child and flattens one level so a
          # transform that returns multiple siblings (e.g. a source block
          # followed by its re-expanded callout paragraphs) stays in
          # document order.
          def flatten_children(children)
            Array(children).flat_map { |child| flatten_one(transform(child)) }
          end

          def flatten_one(result)
            result.is_a?(Array) ? result : [result]
          end

          def transform_block(block)
            content = block.renderable_content

            semantic = resolve_semantic_type(block)

            case semantic
            when :paragraph
              return Coradoc::AsciiDoc::Model::Paragraph.new(
                id: block.id,
                content: create_text_elements(content)
              )
            when :comment
              return Coradoc::AsciiDoc::Model::CommentBlock.new(
                text: safe_content_to_string(content)
              )
            end

            content_text = safe_content_to_string(content)
            result = build_verbatim_block(semantic, block, content_text)
            return result unless verbatim_with_callouts?(semantic, block)

            [result, *build_callout_paragraphs(block.callouts)]
          end

          def build_verbatim_block(semantic, block, content_text)
            case semantic
            when :source_code
              Coradoc::AsciiDoc::Model::Block::SourceCode.new(
                id: block.id,
                title: block.title,
                lang: block.language,
                lines: content_text.split("\n"),
                attributes: build_attributes(block)
              )
            when :quote
              Coradoc::AsciiDoc::Model::Block::Quote.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :example
              Coradoc::AsciiDoc::Model::Block::Example.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :sidebar
              Coradoc::AsciiDoc::Model::Block::Side.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :literal
              Coradoc::AsciiDoc::Model::Block::Literal.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :open
              Coradoc::AsciiDoc::Model::Block::Open.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :pass
              Coradoc::AsciiDoc::Model::Block::Pass.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :listing
              Coradoc::AsciiDoc::Model::Block::Listing.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :verse
              Coradoc::AsciiDoc::Model::Block::Quote.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n"),
                delimiter: '[verse]'
              )
            when :reviewer
              Coradoc::AsciiDoc::Model::Block::ReviewerComment.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            else
              delim = block.delimiter_type.to_s
              delim_char = delim[0]
              delim_len = delim.length

              Coradoc::AsciiDoc::Model::Block::Core.new(
                id: block.id,
                title: block.title,
                delimiter: delim,
                delimiter_char: delim_char,
                delimiter_len: delim_len,
                lines: content_text.split("\n")
              )
            end
          end

          def verbatim_with_callouts?(semantic, block)
            return false unless %i[source_code listing].include?(semantic)
            return false if block.callouts.nil? || block.callouts.empty?

            true
          end

          # Re-expands typed Callouts back into the AsciiDoc `<N> text`
          # paragraph form so the round-trip is faithful.
          def build_callout_paragraphs(callouts)
            callouts.sort_by { |c| c.index || Float::INFINITY }.map do |callout|
              Coradoc::AsciiDoc::Model::Paragraph.new(
                content: create_text_elements("<#{callout.index}> #{callout.content}")
              )
            end
          end

          def transform_table(table)
            rows = Array(table.rows).map do |row|
              columns = Array(row.cells).map do |cell|
                Coradoc::AsciiDoc::Model::TableCell.new(
                  content: cell.flat_text
                )
              end
              Coradoc::AsciiDoc::Model::TableRow.new(
                columns: columns
              )
            end

            Coradoc::AsciiDoc::Model::Table.new(
              id: table.id,
              title: table.title,
              rows: rows
            )
          end

          # Lists nested inside list items carry depth markers so
          # AsciiDoc reads them as nested rather than sibling lists —
          # without this, item children other than text were dropped
          # entirely (#68 territory). Nested lists keep their own
          # marker type one level deeper.
          def transform_list(list, depth = 1)
            items = []
            Array(list.items).each do |item|
              items << Coradoc::AsciiDoc::Model::List::Item.new(
                content: item.flat_text,
                marker: item.marker || (default_marker(list.marker_type) * depth)
              )
              Array(item.children).each do |child|
                next unless child.is_a?(CoreModel::ListBlock)

                # A marker-type change alone signals nesting to
                # AsciiDoc; same-type nesting needs a deeper marker.
                child_depth = child.marker_type == list.marker_type ? depth + 1 : 1
                items.concat(transform_list(child, child_depth).items)
              end
            end

            case list.marker_type
            when 'ordered'
              Coradoc::AsciiDoc::Model::List::Ordered.new(items: items)
            when 'definition'
              Coradoc::AsciiDoc::Model::List::Definition.new(items: items)
            else
              Coradoc::AsciiDoc::Model::List::Unordered.new(items: items)
            end
          end

          def transform_list_item(item)
            Coradoc::AsciiDoc::Model::List::Item.new(
              content: item.flat_text,
              marker: item.marker
            )
          end

          def transform_term(term)
            Coradoc::AsciiDoc::Model::Term.new(
              term: term.text,
              type: term.type&.to_s || 'preferred',
              lang: term.lang || 'en'
            )
          end

          def transform_annotation(annotation)
            Coradoc::AsciiDoc::Model::Admonition.new(
              type: annotation.annotation_type.to_s.upcase,
              content: create_text_elements(annotation.renderable_content)
            )
          end

          # Nested inline structure lives in +children+ (e.g. an
          # ItalicElement whose single child is a BoldElement);
          # +content+ is only the flattened display string. Build the
          # adoc model from children so nesting survives, and default
          # to the constrained marker — the constrained/unstrained
          # distinction is not carried in CoreModel, and constrained
          # is the correct rendering for span-boundary emphasis (#159).
          def inline_model(klass, inline, unconstrained: false)
            content = if inline.children.nil? || inline.children.empty?
                        inline.content.to_s
                      else
                        create_text_elements(inline.children)
                      end

            klass.new(content: content, unconstrained: unconstrained)
          end

          # `_*text*_` parses to Italic{Bold{text}}; Metanorma renders
          # same-span emphasis correctly only with italic innermost
          # (`*_text_*`, #159). When an italic's entire content is one
          # bold (or a bold's one italic), rebuild as Bold outer /
          # Italic inner, both constrained.
          def swap_emphasis_nesting(inline, unconstrained: false)
            children = Array(inline.children)
            return nil unless children.size == 1

            only = children.first
            return nil unless only.is_a?(CoreModel::InlineElement)

            inner_kids = Array(only.children)
            return nil unless inner_kids.empty? || inner_kids.all?(CoreModel::TextContent)

            outer_type = inline.resolve_format_type
            inner_type = only.resolve_format_type
            return nil unless %w[bold italic].include?(outer_type) && outer_type != inner_type &&
                              %w[bold italic].include?(inner_type)

            classes = {
              'bold' => Coradoc::AsciiDoc::Model::Inline::Bold,
              'italic' => Coradoc::AsciiDoc::Model::Inline::Italic
            }
            inner = classes[outer_type].new(
              content: only.children.nil? || only.children.empty? ? only.content.to_s : create_text_elements(only.children),
              unconstrained: false
            )
            classes[inner_type].new(content: inner, unconstrained: unconstrained)
          end

          # AsciiDoc constrained markers only reparse as emphasis when
          # the opening delimiter follows a boundary and the closing
          # one precedes one. CoreModel does not carry the constraint,
          # so derive it from the adjacent sibling text: an inline
          # touching a word character on either side must serialize
          # with the unconstrained form or the emphasis is lost on
          # reparse (mid-word bolding is common in Word documents).
          def unconstrained_flanks?(left, right)
            left_ok = left.nil? || left.match?(/\s/)
            right_ok = right.nil? || right.match?(/\s|[[:punct:]]/)
            !(left_ok && right_ok)
          end

          def sibling_edge(items, index, direction)
            item = items[index]
            text = case item
                   when Coradoc::CoreModel::TextContent then item.text.to_s
                   when Coradoc::CoreModel::InlineElement then item.content.to_s
                   when String then item
                   else return nil
                   end
            return nil if text.empty?

            direction == :last ? text[-1] : text[0]
          end

          def transform_inline(inline, siblings: nil, index: 0)
            left = siblings && index.positive? ? sibling_edge(siblings, index - 1, :last) : nil
            right = siblings ? sibling_edge(siblings, index + 1, :first) : nil
            unconstrained = unconstrained_flanks?(left, right)
            case inline.resolve_format_type
            when 'bold'
              inline_model(Coradoc::AsciiDoc::Model::Inline::Bold, inline,
                           unconstrained: unconstrained)
            when 'italic'
              # #159: italic directly wrapping only bold (`_*text*_`)
              # re-serializes as Bold outer / Italic inner (`*_text_*`)
              # for correct Metanorma rendering.
              swap_emphasis_nesting(inline, unconstrained: unconstrained) ||
                inline_model(Coradoc::AsciiDoc::Model::Inline::Italic, inline,
                             unconstrained: unconstrained)
            when 'monospace'
              Coradoc::AsciiDoc::Model::Inline::Monospace.new(content: inline.content)
            when 'highlight'
              Coradoc::AsciiDoc::Model::Inline::Highlight.new(content: inline.content)
            when 'strikethrough'
              Coradoc::AsciiDoc::Model::Inline::Strikethrough.new(content: inline.content)
            when 'subscript'
              Coradoc::AsciiDoc::Model::Inline::Subscript.new(content: inline.content)
            when 'superscript'
              Coradoc::AsciiDoc::Model::Inline::Superscript.new(content: inline.content)
            when 'underline'
              Coradoc::AsciiDoc::Model::Inline::Underline.new(text: inline.content)
            when 'link'
              Coradoc::AsciiDoc::Model::Inline::Link.new(
                path: inline.target,
                name: inline.content
              )
            when 'xref'
              Coradoc::AsciiDoc::Model::Inline::CrossReference.new(href: inline.target)
            when 'footnote'
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(
                id: inline.target,
                text: inline.content
              )
            when 'stem'
              Coradoc::AsciiDoc::Model::Inline::Stem.new(
                type: inline.stem_type || 'latexmath',
                content: inline.content
              )
            when 'raw_inline'
              Coradoc::AsciiDoc::Model::Inline::Passthrough.new(content: inline.content)
            when 'hard_line_break'
              Coradoc::AsciiDoc::Model::Inline::HardLineBreak.new
            else
              Coradoc::AsciiDoc::Model::TextElement.new(content: inline.content)
            end
          end

          def transform_image(image)
            target_class = if image.inline
                             Coradoc::AsciiDoc::Model::Image::InlineImage
                           else
                             Coradoc::AsciiDoc::Model::Image::BlockImage
                           end
            target_class.new(**image_attributes(image))
          end

          def image_attributes(image)
            {
              src: image.src, alt: image.alt, title: image.title,
              caption: image.caption, width: image.width, height: image.height,
              link: image.link, role: image.role
            }
          end

          def transform_bibliography(bib)
            entries = Array(bib.entries).map do |entry|
              transform_bibliography_entry(entry)
            end

            Coradoc::AsciiDoc::Model::Bibliography.new(
              id: bib.id,
              title: bib.title,
              entries: entries
            )
          end

          def transform_bibliography_entry(entry)
            Coradoc::AsciiDoc::Model::BibliographyEntry.new(
              anchor_name: entry.anchor_name,
              document_id: entry.document_id,
              ref_text: entry.ref_text
            )
          end

          def transform_footnote(footnote)
            Coradoc::AsciiDoc::Model::Inline::Footnote.new(
              id: footnote.id,
              text: footnote.content.to_s
            )
          end

          def transform_footnote_reference(footnote_ref)
            Coradoc::AsciiDoc::Model::Inline::Footnote.new(
              id: footnote_ref.id
            )
          end

          def transform_abbreviation(abbreviation)
            Coradoc::AsciiDoc::Model::TextElement.new(
              content: abbreviation.term.to_s +
                       (abbreviation.definition ? " (#{abbreviation.definition})" : '')
            )
          end

          def transform_definition_list(definition_list, depth = 1)
            delimiter = ':' * (depth + 1)
            items = Array(definition_list.items).map do |item|
              transform_definition_item(item, depth)
            end
            list = Coradoc::AsciiDoc::Model::List::Definition.new(items: items)
            list.delimiter = delimiter
            list
          end

          def transform_definition_item(item, depth = 1)
            delimiter = ':' * (depth + 1)
            # Multi-term `<dt>`: one Term per entry in `item.terms`.
            # Falls back to `[item.term]` for items populated via
            # legacy paths that only set the singular accessor.
            term_strings = terms_for(item)
            terms = term_strings.map do |text|
              Coradoc::AsciiDoc::Model::Term.new(term: text.to_s)
            end
            contents = Array(item.definitions).map do |defn|
              Coradoc::AsciiDoc::Model::TextElement.new(content: defn.to_s)
            end
            di = Coradoc::AsciiDoc::Model::List::DefinitionItem.new(
              terms: terms,
              contents: contents,
              delimiter: delimiter
            )
            di.nested << transform_definition_list(item.nested, depth + 1) if item.nested&.items&.any?
            di
          end

          # Source of truth for "the terms on this <dt>": the `terms`
          # collection when populated, else `[term]` for legacy callers.
          def terms_for(item)
            collection = item.terms if item.is_a?(Coradoc::CoreModel::DefinitionItem)
            return Array(collection) unless collection.nil? || collection.empty?

            primary = item.term
            primary.to_s.empty? ? [] : [primary.to_s]
          end

          def transform_toc(_toc)
            Coradoc::AsciiDoc::Model::TextElement.new(
              content: 'toc::[]'
            )
          end

          def transform_toc_entry(entry)
            Coradoc::AsciiDoc::Model::TextElement.new(
              content: entry.title.to_s
            )
          end

          def transform_comment_line(comment)
            Coradoc::AsciiDoc::Model::CommentLine.new(
              text: comment.text.to_s
            )
          end

          def transform_include(include)
            Coradoc::AsciiDoc::Model::Include.new(
              path: include.target.to_s,
              attributes: build_include_attributes(include),
              line_break: include.line_break.to_s
            )
          end

          private

          def build_include_attributes(include)
            list = Coradoc::AsciiDoc::Model::AttributeList.new
            options = include.options
            return list if options.nil?

            add_tag_attribute(list, options)
            add_simple_attribute(list, 'lines', options.lines_spec)
            add_leveloffset_attribute(list, options)
            add_simple_attribute(list, 'indent', options.indent&.to_s)
            add_simple_attribute(list, 'encoding', options.file_encoding)
            list
          end

          def add_simple_attribute(list, name, value)
            return if value.nil? || value.to_s.empty?

            list.add_named(name, value.to_s)
          end

          def add_tag_attribute(list, options)
            if options.tags_wildcard
              list.add_named('tags', '*')
            elsif options.tags_inverted
              list.add_named('tags', '**')
            elsif options.tags.any?
              list.add_named('tags', options.tags.join(';'))
            end
          end

          def add_leveloffset_attribute(list, options)
            return if options.leveloffset.nil?

            list.add_named('leveloffset', options.leveloffset.to_s)
          end

          # If the first CoreModel child is a FrontmatterBlock, serialize
          # it to YAML text via Codec (single source of truth) and pop it
          # from the children list. Returns [remaining_children,
          # frontmatter_text].
          def extract_frontmatter(children)
            first = children.first
            return [children, nil] unless first.is_a?(CoreModel::FrontmatterBlock)

            yaml = CoreModel::FrontmatterBlock::Codec.to_yaml(first)
            [children.drop(1), yaml.nil? || yaml.empty? ? nil : yaml]
          end

          # Pull the level-0 HeaderElement (the document title) out of the
          # body so the AsciiDoc serializer can render it as `= Title`
          # via Model::Header instead of double-rendering it as a body
          # section. Returns [remaining_children, title_text]. Falls
          # back to +fallback_title+ when no HeaderElement is present
          # (preserves backward compatibility with callers that build
          # DocumentElement programmatically and put the title only on
          # DocumentElement#title rather than in the children list).
          def extract_title_heading(children, fallback_title)
            title_idx = children.index do |c|
              c.is_a?(CoreModel::HeaderElement) && c.level.to_i.zero?
            end
            return [children, fallback_title] unless title_idx

            heading = children[title_idx]
            title_text = heading.title || fallback_title
            remaining = children[0...title_idx] + children[(title_idx + 1)..]
            [remaining, title_text]
          end

          def resolve_semantic_type(block)
            semantic = block.resolve_semantic_type
            return semantic if semantic

            delim = block.delimiter_type
            return nil unless delim && !delim.empty?

            case delim
            when 'comment' then :comment
            when '[verse]' then :verse
            when '>' then :quote
            when "'''", '---', '___', '***' then :horizontal_rule
            else
              char = delim[0]
              DelimiterMapping::CHAR_TO_SEMANTIC[char] || nil
            end
          end

          def safe_content_to_string(content)
            case content
            when String
              content
            when Array
              content.map { |item| safe_content_to_string(item) }.join
            when Coradoc::CoreModel::Base
              content.flat_text
            when Lutaml::Model::Serializable
              if content.is_a?(Coradoc::AsciiDoc::Model::Base)
                content.to_adoc
              elsif content.class.attributes.key?(:text)
                content.text.to_s
              else
                ''
              end
            when nil
              ''
            else
              content.is_a?(String) ? content : ''
            end
          end

          def create_title(text, level)
            return nil if text.nil?

            Coradoc::AsciiDoc::Model::Title.new(
              content: text,
              level_int: level || 1
            )
          end

          def create_text_elements(content)
            case content
            when Array
              content.each_with_index.map do |item, i|
                if item.is_a?(Coradoc::CoreModel::InlineElement)
                  transform_inline(item, siblings: content, index: i)
                else
                  create_text_elements(item)
                end
              end
            when Coradoc::CoreModel::InlineElement
              transform_inline(content)
            when Coradoc::CoreModel::TextContent
              Coradoc::AsciiDoc::Model::TextElement.new(content: content.text.to_s)
            when Coradoc::CoreModel::Base
              transform(content)
            when Coradoc::AsciiDoc::Model::Base
              content
            when Lutaml::Model::Serializable
              text = if content.is_a?(Coradoc::AsciiDoc::Model::Base)
                       content.to_adoc
                     elsif content.class.attributes.key?(:text)
                       content.text.to_s
                     else
                       ''
                     end
              Coradoc::AsciiDoc::Model::TextElement.new(content: text)
            when String
              Coradoc::AsciiDoc::Model::TextElement.new(content: content)
            else
              text = content.is_a?(String) ? content : ''
              Coradoc::AsciiDoc::Model::TextElement.new(content: text)
            end
          end

          def build_attributes(block)
            attrs = {}
            attrs['language'] = block.language if block.language
            attrs
          end

          def default_marker(marker_type)
            case marker_type
            when 'ordered' then '.'
            else '*'
            end
          end
        end

        def transform(model) = self.class.transform(model)
      end
    end
  end
end
