# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Base class for HTML output converters
      #
      # This class handles ONLY CoreModel types for HTML output.
      # Source models should be transformed to CoreModel before HTML conversion:
      #
      #   core_model = Coradoc::Transform::SourceToCoreModel.transform(source_model)
      #   html = Coradoc::Html::Static.convert(core_model)
      #
      class Base
        class << self
          # Convert CoreModel to HTML
          # @param model [Coradoc::CoreModel::Base] CoreModel to convert
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            raise NotImplementedError, "#{self}.to_html must be implemented"
          end

          # Convert content to HTML (CoreModel → HTML)
          # @param content [various] Content to convert
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def convert_content_to_html(content, state = {})
            return '' if content.nil?

            # Handle primitives first
            case content
            when String
              return escape_html(content)
            when Array
              return content.map { |item| convert_content_to_html(item, state) }.join
            when Numeric
              return escape_html(content.to_s)
            when TrueClass, FalseClass
              return escape_html(content.to_s)
            end

            # Handle CoreModel types
            # NOTE: We use is_a? directly instead of defined?() because CoreModel uses autoload.
            # The defined?() check doesn't trigger autoload, so it returns nil even when
            # the class is available via autoload. Using is_a? triggers the autoload.
            return render_core_inline_element(content, state) if content.is_a?(Coradoc::CoreModel::InlineElement)

            return render_core_block(content, state) if content.is_a?(Coradoc::CoreModel::Block)

            if content.is_a?(Coradoc::CoreModel::StructuralElement)
              # Use Section converter for sections
              return Coradoc::Html::Converters::Section.to_html(content, state) if content.element_type == 'section'

              return render_core_structural_element(content, state)
            end

            return render_core_list_block(content, state) if content.is_a?(Coradoc::CoreModel::ListBlock)

            return render_core_list_item(content, state) if content.is_a?(Coradoc::CoreModel::ListItem)

            return render_core_annotation_block(content, state) if content.is_a?(Coradoc::CoreModel::AnnotationBlock)

            return Coradoc::Html::Converters::Table.to_html(content, state) if content.is_a?(Coradoc::CoreModel::Table)

            return render_core_table_row(content, state) if content.is_a?(Coradoc::CoreModel::TableRow)

            return render_core_table_cell(content, state) if content.is_a?(Coradoc::CoreModel::TableCell)

            return render_core_term(content, state) if content.is_a?(Coradoc::CoreModel::Term)

            if content.is_a?(Coradoc::CoreModel::Image)
              return render_core_inline_image(content, state) if content.inline

              return render_core_block_image(content, state)

            end

            return render_core_footnote(content, state) if content.is_a?(Coradoc::CoreModel::Footnote)

            if content.is_a?(Coradoc::CoreModel::FootnoteReference)
              return render_core_footnote_reference(content,
                                                    state)
            end

            return render_core_abbreviation(content, state) if content.is_a?(Coradoc::CoreModel::Abbreviation)

            return render_core_definition_list(content, state) if content.is_a?(Coradoc::CoreModel::DefinitionList)

            return render_core_definition_item(content, state) if content.is_a?(Coradoc::CoreModel::DefinitionItem)

            return render_core_toc(content, state) if content.is_a?(Coradoc::CoreModel::Toc)

            return render_core_toc_entry(content, state) if content.is_a?(Coradoc::CoreModel::TocEntry)

            return render_core_bibliography(content, state) if content.is_a?(Coradoc::CoreModel::Bibliography)

            return render_core_bibliography_entry(content, state) if content.is_a?(Coradoc::CoreModel::BibliographyEntry)

            # Handle unknown types gracefully
            handle_unknown_content(content, state)
          end

          # === CoreModel rendering methods ===

          # Render CoreModel inline element
          def render_core_inline_element(element, state = {})
            case element.format_type
            when 'bold'
              "<strong>#{convert_content_to_html(element.content, state)}</strong>"
            when 'italic'
              "<em>#{convert_content_to_html(element.content, state)}</em>"
            when 'monospace'
              "<code>#{convert_content_to_html(element.content, state)}</code>"
            when 'superscript'
              "<sup>#{convert_content_to_html(element.content, state)}</sup>"
            when 'subscript'
              "<sub>#{convert_content_to_html(element.content, state)}</sub>"
            when 'underline'
              "<u>#{convert_content_to_html(element.content, state)}</u>"
            when 'strikethrough'
              "<del>#{convert_content_to_html(element.content, state)}</del>"
            when 'highlight'
              "<mark>#{convert_content_to_html(element.content, state)}</mark>"
            when 'link'
              href = element.target || element.metadata&.dig(:href) || '#'
              "<a href=\"#{escape_attribute(href)}\">#{convert_content_to_html(element.content, state)}</a>"
            when 'xref'
              href = element.target || element.metadata&.dig(:href) || '#'
              "<a href=\"##{escape_attribute(href)}\">#{convert_content_to_html(element.content, state)}</a>"
            when 'footnote'
              footnote_id = element.target || element.metadata&.dig(:id) || ''
              "<sup class=\"footnote\" id=\"fn-#{escape_attribute(footnote_id)}\">#{convert_content_to_html(
                element.content, state
              )}</sup>"
            when 'stem'
              "<code class=\"stem\">#{escape_html(element.content)}</code>"
            when 'term'
              # Term reference: term:[text] or term:[text,display]
              %(<span class="term" data-term-ref="#{escape_attribute(element.content)}">#{escape_html(element.content)}</span>)
            when 'break'
              break_type = element.metadata&.dig(:break_type) || 'thematic'
              break_type == 'thematic' ? '<hr>' : '<br>'
            when 'quotation'
              "<q>#{convert_content_to_html(element.content, state)}</q>"
            when 'small'
              "<small>#{convert_content_to_html(element.content, state)}</small>"
            when 'span'
              render_core_span(element, state)
            else
              convert_content_to_html(element.content, state)
            end
          end

          # Render CoreModel span
          def render_core_span(element, state = {})
            attrs = build_class_attribute(element.metadata&.dig(:class))
            "<span#{attrs}>#{convert_content_to_html(element.content, state)}</span>"
          end

          # Render CoreModel block
          def render_core_block(block, state = {})
            attrs = build_html_attributes(block.id, block.title)

            # Get renderable content (children if present, otherwise content)
            renderable = block.respond_to?(:renderable_content) ? block.renderable_content : block.content

            # Check element_type first for paragraph handling
            case block.element_type
            when 'paragraph'
              content = convert_content_to_html(renderable, state)
              return "<p#{attrs}>#{content}</p>" if content && !content.empty?

              ''
            end

            # Then check delimiter_type for special blocks
            case block.delimiter_type
            when '----', 'source'
              lang = block.language || block.metadata&.dig(:language)
              lang_attr = lang ? " data-lang=\"#{escape_attribute(lang)}\"" : ''
              "<pre#{attrs}><code#{lang_attr}>#{escape_html(block.content)}</code></pre>"
            when '____'
              "<blockquote#{attrs}>#{convert_content_to_html(block.content, state)}</blockquote>"
            when '===='
              "<div class=\"example\"#{attrs}>#{convert_content_to_html(block.content, state)}</div>"
            when '****'
              "<aside class=\"sidebar\"#{attrs}>#{convert_content_to_html(block.content, state)}</aside>"
            when '....'
              "<pre class=\"literal\"#{attrs}>#{escape_html(block.content)}</pre>"
            when '++++'
              block.content.to_s # Pass through
            when 'comment'
              '' # Skip comments in output
            when '***', '---', '___'
              "<hr#{attrs}>"
            else
              "<div#{attrs}>#{convert_content_to_html(block.content, state)}</div>"
            end
          end

          # Render CoreModel structural element
          def render_core_structural_element(element, state = {})
            attrs = build_html_attributes(element.id, nil)

            children_html = (element.children || []).map { |c| convert_content_to_html(c, state) }.join
            case element.element_type
            when 'document'
              "<article#{attrs}>#{children_html}</article>"
            when 'header'
              "<header#{attrs}>#{children_html}</header>"
            when 'section'
              level = element.level || 1
              level = [level, 6].min
              title_html = element.title ? "<h#{level}>#{escape_html(element.title)}</h#{level}>" : ''
              "<section#{attrs}>#{title_html}#{children_html}</section>"
            else
              "<div#{attrs}>#{children_html}</div>"
            end
          end

          # Render CoreModel list block
          def render_core_list_block(list, state = {})
            attrs = build_html_attributes(list.id, list.title)

            items_html = (list.items || []).map { |i| convert_content_to_html(i, state) }.join
            case list.marker_type
            when 'unordered'
              "<ul#{attrs}>#{items_html}</ul>"
            when 'ordered'
              "<ol#{attrs}>#{items_html}</ol>"
            when 'definition'
              "<dl#{attrs}>#{items_html}</dl>"
            else
              "<ul#{attrs}>#{items_html}</ul>"
            end
          end

          # Render CoreModel list item
          def render_core_list_item(item, state = {})
            # Use renderable_content to get children if present
            renderable = item.respond_to?(:renderable_content) ? item.renderable_content : item.content
            content = convert_content_to_html(renderable, state)

            # Handle nested list
            content += convert_content_to_html(item.nested_list, state) if item.nested_list

            "<li>#{content}</li>"
          end

          # Render CoreModel annotation block (admonition)
          def render_core_annotation_block(block, state = {})
            attrs = build_html_attributes(block.id, block.title)
            type_class = block.annotation_type ? " #{escape_html(block.annotation_type)}" : ''
            label = block.annotation_label || block.annotation_type&.upcase

            html = "<div class=\"admonition#{type_class}\"#{attrs}>"
            html += "<div class=\"admonition-label\">#{escape_html(label)}</div>" if label
            html += convert_content_to_html(block.content, state)
            html += '</div>'
            html
          end

          # Render CoreModel table row
          def render_core_table_row(row, state = {})
            cells = row.cells || row.columns || []
            cells_html = cells.map { |c| convert_content_to_html(c, state) }.join
            tag = row.header ? 'thead' : 'tr'
            "<#{tag}>#{cells_html}</#{tag}>"
          end

          # Render CoreModel table cell
          def render_core_table_cell(cell, state = {})
            tag = cell.header ? 'th' : 'td'
            attrs = ''
            attrs += " colspan=\"#{cell.colspan}\"" if cell.colspan
            attrs += " rowspan=\"#{cell.rowspan}\"" if cell.rowspan
            attrs += " style=\"text-align: #{escape_html(cell.alignment)}\"" if cell.alignment

            # Use renderable_content to get children if present, otherwise content
            renderable = cell.respond_to?(:renderable_content) ? cell.renderable_content : (cell.content || cell.text)
            content = convert_content_to_html(renderable, state)
            "<#{tag}#{attrs}>#{content}</#{tag}>"
          end

          # Render CoreModel term
          def render_core_term(term, _state = {})
            term_text = term.text || ''
            term_type = term.term_type || term.type || 'term'
            display_text = term.render_text&.strip&.empty? ? false : term.render_text
            display_text ||= term_text

            %(<span class="term term-#{escape_attribute(term_type)}" data-term-ref="#{escape_attribute(term_text)}">#{escape_html(display_text)}</span>)
          end

          # Render CoreModel inline image
          def render_core_inline_image(image, _state = {})
            attrs = "src=\"#{escape_attribute(image.src)}\""
            attrs += " alt=\"#{escape_attribute(image.alt)}\"" if image.alt
            attrs += " width=\"#{escape_attribute(image.width)}\"" if image.width
            attrs += " height=\"#{escape_attribute(image.height)}\"" if image.height

            %(<img #{attrs}>)
          end

          # Render CoreModel block image
          def render_core_block_image(image, _state = {})
            attrs = build_html_attributes(image.id, nil)
            img_attrs = "src=\"#{escape_attribute(image.src)}\""
            img_attrs += " alt=\"#{escape_attribute(image.alt)}\"" if image.alt
            img_attrs += " width=\"#{escape_attribute(image.width)}\"" if image.width
            img_attrs += " height=\"#{escape_attribute(image.height)}\"" if image.height

            html = "<figure#{attrs}>"
            html += %(<img #{img_attrs}>)
            html += "<figcaption>#{escape_html(image.caption)}</figcaption>" if image.caption
            html += '</figure>'
            html
          end

          # Render CoreModel footnote
          def render_core_footnote(footnote, state = {})
            footnote_id = footnote.id || ''
            content = footnote.content || footnote.inline_content

            if footnote_id.empty?
              # Anonymous footnote
              text = content.is_a?(Array) ? content.join : content.to_s
              title_text = text[0..50]
              %(<sup class="footnote" title="#{escape_attribute(title_text)}">#{convert_content_to_html(content,
                                                                                                        state)}</sup>)
            else
              # Named footnote reference
              %(<sup class="footnote"><a href="#fn-#{escape_attribute(footnote_id)}" id="fnref-#{escape_attribute(footnote_id)}">#{escape_html(footnote_id)}</a></sup>)
            end
          end

          # Render CoreModel footnote reference
          def render_core_footnote_reference(ref, _state = {})
            footnote_id = ref.id || ''
            %(<sup class="footnote"><a href="#fn-#{escape_attribute(footnote_id)}">[#{escape_html(footnote_id)}]</a></sup>)
          end

          # Render CoreModel abbreviation
          def render_core_abbreviation(abbr, _state = {})
            term = abbr.term || ''
            definition = abbr.definition || ''
            %(<abbr title="#{escape_attribute(definition)}">#{escape_html(term)}</abbr>)
          end

          # Render CoreModel definition list
          def render_core_definition_list(dl, state = {})
            attrs = build_html_attributes(dl.id, dl.title)
            items_html = (dl.items || []).map { |i| convert_content_to_html(i, state) }.join
            "<dl#{attrs}>#{items_html}</dl>"
          end

          # Render CoreModel definition item
          def render_core_definition_item(item, state = {})
            term_html = convert_content_to_html(item.term, state)
            definitions_html = (item.definitions || []).map { |d| "<dd>#{convert_content_to_html(d, state)}</dd>" }.join
            "<dt>#{term_html}</dt>#{definitions_html}"
          end

          # Render CoreModel TOC
          def render_core_toc(toc, state = {})
            attrs = build_html_attributes(nil, nil)
            attrs += ' class="toc"'
            entries_html = (toc.entries || []).map { |e| convert_content_to_html(e, state) }.join
            "<nav#{attrs}><h2>Table of Contents</h2><ul>#{entries_html}</ul></nav>"
          end

          # Render CoreModel TOC entry
          def render_core_toc_entry(entry, state = {})
            id = entry.id || ''
            title = entry.title || ''
            entry.level || 1
            number = entry.number
            display_title = number ? "#{number}. #{title}" : title

            item_html = if id.empty?
                          escape_html(display_title)
                        else
                          %(<a href="##{escape_attribute(id)}">#{escape_html(display_title)}</a>)
                        end

            children_html = (entry.children || []).map { |c| convert_content_to_html(c, state) }.join
            children_html = "<ul>#{children_html}</ul>" unless children_html.empty?

            "<li>#{item_html}#{children_html}</li>"
          end

          def render_core_bibliography(bib, state = {})
            attrs = %( class="bibliography")
            attrs += %( id="#{escape_attribute(bib.id)}") if bib.id

            title_html = (%(<h2 class="bibliography-title">#{escape_html(bib.title)}</h2>) if bib.title && !bib.title.to_s.empty?)

            entries_html = Array(bib.entries).map { |e| convert_content_to_html(e, state) }.join("\n")

            inner = ''
            inner += "#{title_html}\n" if title_html
            inner += "<div class=\"bibliography-entries\">\n#{entries_html}\n</div>" unless entries_html.empty?

            "<section#{attrs}>\n#{inner}\n</section>"
          end

          def render_core_bibliography_entry(entry, _state = {})
            entry_id = entry.anchor_name || entry.document_id
            anchor_html = entry_id ? %(<a id="#{escape_attribute(entry_id)}" class="bibliography-anchor"></a>) : ''
            label = entry.document_id || ''
            ref_text = entry.ref_text || ''
            label_html = label.empty? ? '' : %(<span class="bibliography-label">#{escape_html(label)}</span> )

            "<div class=\"bibliography-entry\">#{anchor_html}#{label_html}#{escape_html(ref_text)}</div>"
          end

          # Handle unknown content types
          def handle_unknown_content(content, _state = {})
            if content.is_a?(Coradoc::CoreModel::Base)
              raise ArgumentError,
                    "Unknown CoreModel type for HTML conversion: #{content.class}. " \
                    'Expected a recognized CoreModel type.'
            end

            # Handle non-CoreModel types (strings from mixed content, etc.)
            escape_html(content.to_s)
          end

          # Extract text from unknown model types as a fallback
          def extract_text_fallback(content)
            # Try text attribute first
            if content.respond_to?(:text) && content.text
              text_val = content.text
              return text_val if text_val.is_a?(String)
              return text_val.to_s if text_val.respond_to?(:to_s)
            end

            # Try content attribute
            if content.respond_to?(:content) && content.content
              content_val = content.content
              if content_val.is_a?(String)
                return content_val
              elsif content_val.is_a?(Array)
                return content_val.map { |item| convert_content_to_html(item, {}) }.join
              end
            end

            # Try href attribute (for cross-references)
            return content.href.to_s if content.respond_to?(:href) && content.href

            # Try term attribute (for term references)
            return content.term.to_s if content.respond_to?(:term) && content.term

            # Try id attribute (for references with IDs)
            return content.id.to_s if content.respond_to?(:id) && content.id

            # Try name attribute
            return content.name.to_s if content.respond_to?(:name) && content.name

            # Try to_adoc if available (for AsciiDoc models)
            return content.to_adoc.to_s if content.respond_to?(:to_adoc)

            ''
          end

          # === Helper methods ===

          # Build HTML attributes string
          def build_html_attributes(id, title)
            attrs = ''
            attrs += " id=\"#{escape_attribute(id)}\"" if id && !id.to_s.empty?
            attrs += " title=\"#{escape_attribute(title)}\"" if title && !title.to_s.empty?
            attrs
          end

          # Build class attribute
          def build_class_attribute(class_name)
            class_name ? " class=\"#{escape_attribute(class_name)}\"" : ''
          end

          # Find converter for model class
          def find_converter_for_model(model_class)
            Coradoc::Html::Base.find_converter(model_class)
          end

          # Type-safe lookup of converter class by name
          def find_converter_class_by_name(converter_name)
            klass = Coradoc::Html::Converters.const_get(converter_name, false)
            return klass if klass <= Coradoc::Html::Converters::Base

            nil
          rescue NameError
            nil
          end

          # Escape HTML entities
          def escape_html(text)
            Coradoc::Html::Base.escape_html(text)
          end

          # Escape HTML attribute values
          def escape_attribute(value)
            return '' if value.nil?

            value.to_s.gsub(/&/, '&amp;').gsub(/"/, '&quot;').gsub(/</, '&lt;').gsub(/>/, '&gt;')
          end

          # Build HTML element
          def build_element(tag, content = nil, attributes = {})
            Coradoc::Html::Base.build_element(tag, content, attributes)
          end

          # Extract attributes from a CoreModel
          # @param model [Coradoc::CoreModel::Base] Model to extract attributes from
          # @return [Hash] Attributes hash
          def extract_model_attributes(model)
            Coradoc::Html::Base.extract_attributes(model)
          end

          # === HTML Input Direction (HTML → CoreModel) ===

          # Process children of an HTML node
          # @param node [Nokogiri::XML::Node] Parent node
          # @param state [Hash] Conversion state
          # @return [Array] Array of converted content
          def treat_children(node, state = {})
            return [] unless node&.children

            node.children.flat_map do |child|
              convert_node_to_core(child, state)
            end.compact
          end

          # Convert HTML node to CoreModel
          # @param node [Nokogiri::XML::Node] Node to convert
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::Base, String, nil]
          def convert_node_to_core(node, state = {})
            case node.type
            when Nokogiri::XML::Node::TEXT_NODE
              text = node.text
              return nil if text.strip.empty? && !state[:preserve_whitespace]

              text
            when Nokogiri::XML::Node::ELEMENT_NODE
              convert_element_to_core(node, state)
            when Nokogiri::XML::Node::COMMENT_NODE
              nil # Skip comments
            end
          end

          # Convert HTML element to CoreModel
          # @param node [Nokogiri::XML::Node] Element node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::Base, Array, nil]
          def convert_element_to_core(node, state = {})
            # Delegate to Html::Input::Converters for HTML input
            # This maintains separation between input and output converters
            if defined?(Coradoc::Html::Input::Converters)
              converter = Coradoc::Html::Input::Converters.lookup(node.name)
              if converter
                result = converter.to_coradoc(node, state)
                # Transform to CoreModel if needed
                return transform_to_coremodel(result) if result
              end
            end

            # Fallback: treat children
            treat_children(node, state)
          end

          # Transform model to CoreModel
          # @param model [Object] Model to transform
          # @return [Coradoc::CoreModel::Base, Object]
          def transform_to_coremodel(model)
            # Already a CoreModel type - return as-is
            model
          end

          # Extract attributes from HTML node
          # @param node [Nokogiri::XML::Node] HTML node
          # @return [Hash] Attributes hash
          def extract_node_attributes(node)
            return {} unless node.is_a?(Nokogiri::XML::Node)

            node.attributes.each_with_object({}) do |(name, attr), hash|
              hash[name.to_sym] = attr.value
            end
          end
        end
      end
    end
  end
end
