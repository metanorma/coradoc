# frozen_string_literal: true

require 'nokogiri'
require 'coradoc/html/node_builder'

module Coradoc
  module Html
    module Converters
      # Base class for HTML output converters
      #
      # This class handles ONLY CoreModel types for HTML output.
      # All HTML elements are constructed using Nokogiri — never by
      # concatenating raw HTML strings.
      class Base
        class << self
          # Convert CoreModel to HTML
          def to_html(model, state = {})
            raise NotImplementedError, "#{self}.to_html must be implemented"
          end

          # Convert content to HTML (CoreModel → HTML)
          def convert_content_to_html(content, state = {})
            return '' if content.nil?

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

            return render_core_inline_element(content, state) if content.is_a?(Coradoc::CoreModel::InlineElement)
            return render_core_annotation_block(content, state) if content.is_a?(Coradoc::CoreModel::AnnotationBlock)
            return render_core_block(content, state) if content.is_a?(Coradoc::CoreModel::Block)

            if content.is_a?(Coradoc::CoreModel::StructuralElement)
              return Coradoc::Html::Converters::Section.to_html(content, state) if content.section?

              return render_core_structural_element(content, state)
            end

            return render_core_list_block(content, state) if content.is_a?(Coradoc::CoreModel::ListBlock)
            return render_core_list_item(content, state) if content.is_a?(Coradoc::CoreModel::ListItem)
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

            if content.is_a?(Coradoc::CoreModel::BibliographyEntry)
              return render_core_bibliography_entry(content,
                                                    state)
            end

            handle_unknown_content(content, state)
          end

          # === CoreModel rendering methods ===

          def render_core_inline_element(element, state = {})
            content_html = convert_content_to_html(element.content, state)

            case element.resolve_format_type
            when 'bold'
              NodeBuilder.build(:strong, content_html).to_html
            when 'italic'
              NodeBuilder.build(:em, content_html).to_html
            when 'monospace'
              NodeBuilder.build(:code, content_html).to_html
            when 'superscript'
              NodeBuilder.build(:sup, content_html).to_html
            when 'subscript'
              NodeBuilder.build(:sub, content_html).to_html
            when 'underline'
              NodeBuilder.build(:u, content_html).to_html
            when 'strikethrough'
              NodeBuilder.build(:del, content_html).to_html
            when 'highlight'
              NodeBuilder.build(:mark, content_html).to_html
            when 'link'
              href = element.target || element.metadata&.dig(:href) || '#'
              NodeBuilder.build(:a, content_html, href: href).to_html
            when 'xref'
              href = element.target || element.metadata&.dig(:href) || '#'
              NodeBuilder.build(:a, content_html, href: "##{href}").to_html
            when 'footnote'
              footnote_id = element.target || element.metadata&.dig(:id) || ''
              NodeBuilder.build(:sup, content_html, class: 'footnote', id: "fn-#{footnote_id}").to_html
            when 'stem'
              NodeBuilder.build(:code, escape_html(element.content), class: 'stem').to_html
            when 'term'
              node = NodeBuilder.build(:span, escape_html(element.content),
                                       class: 'term')
              node['data-term-ref'] = element.content.to_s
              node.to_html
            when 'break'
              break_type = element.metadata&.dig(:break_type) || 'thematic'
              break_type == 'thematic' ? NodeBuilder.build(:hr).to_html : NodeBuilder.build(:br).to_html
            when 'quotation'
              NodeBuilder.build(:q, content_html).to_html
            when 'small'
              NodeBuilder.build(:small, content_html).to_html
            when 'span'
              render_core_span(element, state)
            else
              content_html
            end
          end

          def render_core_span(element, state = {})
            class_name = element.metadata&.dig(:class)
            content_html = convert_content_to_html(element.content, state)
            attrs = {}
            attrs[:class] = class_name if class_name
            NodeBuilder.build(:span, content_html, **attrs).to_html
          end

          def render_core_block(block, state = {})
            renderable = block.renderable_content
            semantic = resolve_block_semantic_type(block)

            case semantic
            when :paragraph
              content = convert_content_to_html(renderable, state)
              return '' if content.nil? || content.empty?

              attrs = build_id_title_attrs(block.id, block.title)
              NodeBuilder.build(:p, content, **attrs).to_html
            when :source_code
              lang = block.language || block.metadata&.dig(:language)
              code_attrs = {}
              code_attrs[:'data-lang'] = lang if lang
              pre_attrs = build_id_title_attrs(block.id, block.title)
              code_node = NodeBuilder.build(:code, escape_html(block.flat_text), **code_attrs)
              NodeBuilder.build(:pre, code_node, **pre_attrs).to_html
            when :quote, :verse
              attrs = build_id_title_attrs(block.id, block.title)
              NodeBuilder.build(:blockquote, convert_content_to_html(renderable, state), **attrs).to_html
            when :example
              attrs = build_id_title_attrs(block.id, block.title)
              node = NodeBuilder.build(:div, convert_content_to_html(renderable, state), **attrs)
              node['class'] = 'example'
              node.to_html
            when :sidebar
              attrs = build_id_title_attrs(block.id, block.title)
              node = NodeBuilder.build(:aside, convert_content_to_html(renderable, state), **attrs)
              node['class'] = 'sidebar'
              node.to_html
            when :literal
              attrs = build_id_title_attrs(block.id, block.title)
              node = NodeBuilder.build(:pre, escape_html(block.flat_text), **attrs)
              node['class'] = 'literal'
              node.to_html
            when :pass
              block.flat_text
            when :listing
              attrs = build_id_title_attrs(block.id, block.title)
              NodeBuilder.build(:pre, escape_html(block.flat_text), **attrs).to_html
            when :open
              attrs = build_id_title_attrs(block.id, block.title)
              NodeBuilder.build(:div, convert_content_to_html(renderable, state), **attrs).to_html
            when :comment, :reviewer
              ''
            when :horizontal_rule
              NodeBuilder.build(:hr).to_html
            else
              attrs = build_id_title_attrs(block.id, block.title)
              NodeBuilder.build(:div, convert_content_to_html(renderable, state), **attrs).to_html
            end
          end

          def resolve_block_semantic_type(block)
            block.resolve_semantic_type
          end

          def render_core_structural_element(element, state = {})
            attrs = build_id_title_attrs(element.id, nil)
            children_html = (element.children || []).map { |c| convert_content_to_html(c, state) }.join

            case element.element_type
            when 'document'
              NodeBuilder.build(:article, children_html, **attrs).to_html
            when 'header'
              NodeBuilder.build(:header, children_html, **attrs).to_html
            when 'section'
              level = element.heading_level
              level = [level, 6].min
              title_node = (NodeBuilder.build("h#{level}", escape_html(element.title)) if element.title)
              children_nodes = []
              children_nodes << title_node if title_node
              children_nodes << children_html unless children_html.empty?
              NodeBuilder.build(:section, children_nodes, **attrs).to_html
            else
              NodeBuilder.build(:div, children_html, **attrs).to_html
            end
          end

          def render_core_list_block(list, state = {})
            attrs = build_id_title_attrs(list.id, list.title)
            items_html = (list.items || []).map { |i| convert_content_to_html(i, state) }.join

            case list.marker_type
            when 'unordered'
              NodeBuilder.build(:ul, items_html, **attrs).to_html
            when 'ordered'
              NodeBuilder.build(:ol, items_html, **attrs).to_html
            when 'definition'
              NodeBuilder.build(:dl, items_html, **attrs).to_html
            else
              NodeBuilder.build(:ul, items_html, **attrs).to_html
            end
          end

          def render_core_list_item(item, state = {})
            renderable = item.renderable_content
            content = convert_content_to_html(renderable, state)
            content += convert_content_to_html(item.nested_list, state) if item.nested_list
            NodeBuilder.build(:li, content).to_html
          end

          def render_core_annotation_block(block, state = {})
            attrs = build_id_title_attrs(block.id, block.title)
            type = block.annotation_type ? block.annotation_type.to_s.downcase : 'note'
            label = block.annotation_label || type.upcase

            icon_title = NodeBuilder.build(:span, escape_html(label), class: 'title')
            icon_div = NodeBuilder.build(:div, icon_title, class: 'icon')

            renderable = block.renderable_content
            content_html = convert_content_to_html(renderable, state)
            content_html = process_inline_patterns(content_html)
            content_div = NodeBuilder.build(:div, content_html, class: 'content')

            NodeBuilder.build(:div, [icon_div, content_div],
                              class: "admonitionblock #{type}", **attrs).to_html
          end

          def render_core_table_row(row, state = {})
            cells = row.cells || row.columns || []
            cells_html = cells.map { |c| convert_content_to_html(c, state) }.join
            tag = row.header ? :thead : :tr
            NodeBuilder.build(tag, cells_html).to_html
          end

          def render_core_table_cell(cell, state = {})
            tag = cell.header ? :th : :td
            attrs = {}
            attrs[:colspan] = cell.colspan.to_s if cell.colspan
            attrs[:rowspan] = cell.rowspan.to_s if cell.rowspan
            attrs[:style] = "text-align: #{cell.alignment}" if cell.alignment

            renderable = cell.renderable_content
            content = convert_content_to_html(renderable, state)
            NodeBuilder.build(tag, content, **attrs).to_html
          end

          def render_core_term(term, _state = {})
            term_text = term.text || ''
            term_type = term.term_type || term.type || 'term'
            display_text = term.render_text&.strip&.empty? ? false : term.render_text
            display_text ||= term_text

            node = NodeBuilder.build(:span, escape_html(display_text),
                                     class: "term term-#{term_type}")
            node['data-term-ref'] = term_text
            node.to_html
          end

          def render_core_inline_image(image, _state = {})
            attrs = { src: image.src }
            attrs[:alt] = image.alt if image.alt
            attrs[:width] = image.width if image.width
            attrs[:height] = image.height if image.height
            NodeBuilder.build(:img, nil, **attrs).to_html
          end

          def render_core_block_image(image, _state = {})
            fig_attrs = build_id_title_attrs(image.id, nil)
            img_attrs = { src: image.src }
            img_attrs[:alt] = image.alt if image.alt
            img_attrs[:width] = image.width if image.width
            img_attrs[:height] = image.height if image.height

            img_node = NodeBuilder.build(:img, nil, **img_attrs)
            children = [img_node]
            children << NodeBuilder.build(:figcaption, escape_html(image.caption)) if image.caption

            NodeBuilder.build(:figure, children, **fig_attrs).to_html
          end

          def render_core_footnote(footnote, state = {})
            footnote_id = footnote.id || ''
            content = footnote.content || footnote.inline_content

            if footnote_id.empty?
              text = content.is_a?(Array) ? content.join : content.to_s
              title_text = text[0..50]
              inner = convert_content_to_html(content, state)
              NodeBuilder.build(:sup, inner, class: 'footnote', title: title_text).to_html
            else
              link = NodeBuilder.build(:a, escape_html(footnote_id),
                                       href: "#fn-#{footnote_id}", id: "fnref-#{footnote_id}")
              NodeBuilder.build(:sup, link, class: 'footnote').to_html
            end
          end

          def render_core_footnote_reference(ref, _state = {})
            footnote_id = ref.id || ''
            link = NodeBuilder.build(:a, "[#{footnote_id}]", href: "#fn-#{footnote_id}")
            NodeBuilder.build(:sup, link, class: 'footnote').to_html
          end

          def render_core_abbreviation(abbr, _state = {})
            term = abbr.term || ''
            definition = abbr.definition || ''
            NodeBuilder.build(:abbr, escape_html(term), title: definition).to_html
          end

          def render_core_definition_list(dl, state = {})
            attrs = build_id_title_attrs(dl.id, dl.title)
            items_html = (dl.items || []).map { |i| convert_content_to_html(i, state) }.join
            NodeBuilder.build(:dl, items_html, **attrs).to_html
          end

          def render_core_definition_item(item, state = {})
            term_text = item.term.to_s
            term_html, term_id = process_definition_term(term_text)
            dt_attrs = {}
            dt_attrs[:id] = term_id if term_id

            dt_node = NodeBuilder.build(:dt, term_html, **dt_attrs)
            dd_nodes = (item.definitions || []).map do |d|
              dd_content = process_inline_patterns(convert_content_to_html(d, state))
              NodeBuilder.build(:dd, dd_content)
            end

            NodeBuilder.build(:fragment, [dt_node, *dd_nodes]).to_html
          end

          def process_definition_term(text)
            id = nil
            if text =~ /\A\[\[([^\]]+)\]\]/
              id = ::Regexp.last_match(1)
              text = ::Regexp.last_match.post_match
            end
            html = process_inline_patterns(escape_html(text))
            [html, id]
          end

          # Post-process text to convert inline AsciiDoc patterns to HTML
          def process_inline_patterns(html)
            doc = Nokogiri::HTML::DocumentFragment.parse(html)
            text_nodes = []
            doc.traverse do |node|
              text_nodes << node if node.text?
            end

            text_nodes.each do |t_node|
              original = t_node.text
              modified = original.gsub(/`([^`]+)`/) { "<code>#{escape_html(::Regexp.last_match(1))}</code>" }
              modified = modified.gsub(/&lt;&lt;([^&]+)&gt;&gt;/) do
                ref = ::Regexp.last_match(1)
                "<a href=\"##{escape_attribute(ref)}\">#{escape_html(ref)}</a>"
              end
              t_node.replace(Nokogiri::HTML::DocumentFragment.parse(modified)) if modified != original
            end

            doc.to_html
          end

          def render_core_toc(toc, state = {})
            attrs = build_id_title_attrs(nil, nil)
            entries_html = (toc.entries || []).map { |e| convert_content_to_html(e, state) }.join
            h2 = NodeBuilder.build(:h2, 'Table of Contents')
            ul = NodeBuilder.build(:ul, entries_html)
            node = NodeBuilder.build(:nav, [h2, ul], class: 'toc', **attrs)
            node.to_html
          end

          def render_core_toc_entry(entry, state = {})
            id = entry.id || ''
            title = entry.title || ''
            number = entry.number
            display_title = number ? "#{number}. #{title}" : title

            item_node = if id.empty?
                          NodeBuilder.build(:fragment, escape_html(display_title))
                        else
                          NodeBuilder.build(:a, escape_html(display_title), href: "##{id}")
                        end

            children_html = (entry.children || []).map { |c| convert_content_to_html(c, state) }.join
            li_children = [item_node]
            li_children << NodeBuilder.build(:ul, children_html) unless children_html.empty?

            NodeBuilder.build(:li, li_children).to_html
          end

          def render_core_bibliography(bib, state = {})
            attrs = { class: 'bibliography' }
            attrs[:id] = bib.id if bib.id

            children = []
            if bib.title && !bib.title.to_s.empty?
              children << NodeBuilder.build(:h2, escape_html(bib.title),
                                            class: 'bibliography-title')
            end

            entries_html = Array(bib.entries).map { |e| convert_content_to_html(e, state) }.join("\n")
            children << NodeBuilder.build(:div, entries_html, class: 'bibliography-entries') unless entries_html.empty?

            NodeBuilder.build(:section, children, **attrs).to_html
          end

          def render_core_bibliography_entry(entry, _state = {})
            entry_id = entry.anchor_name || entry.document_id
            children = []
            children << NodeBuilder.build(:a, nil, id: entry_id, class: 'bibliography-anchor') if entry_id
            label = entry.document_id || ''
            unless label.empty?
              label_span = NodeBuilder.build(:span, escape_html(label), class: 'bibliography-label')
              children << label_span
              children << NodeBuilder.text(' ')
            end
            ref_text = entry.ref_text || ''
            children << NodeBuilder.text(escape_html(ref_text))

            NodeBuilder.build(:div, children, class: 'bibliography-entry').to_html
          end

          def handle_unknown_content(content, _state = {})
            if content.is_a?(Coradoc::CoreModel::Base)
              raise ArgumentError,
                    "Unknown CoreModel type for HTML conversion: #{content.class}. " \
                    'Expected a recognized CoreModel type.'
            end

            escape_html(content.to_s)
          end

          def extract_text_fallback(content)
            if content.is_a?(Coradoc::CoreModel::Base)
              if content.class.attributes.key?(:text) && content.text
                text_val = content.text
                return text_val if text_val.is_a?(String)

                return text_val.to_s
              end

              if content.class.attributes.key?(:content) && content.content
                content_val = content.content
                if content_val.is_a?(String)
                  return content_val
                elsif content_val.is_a?(Array)
                  return content_val.map { |item| convert_content_to_html(item, {}) }.join
                end
              end

              return content.href.to_s if content.class.attributes.key?(:href) && content.href
              return content.term.to_s if content.class.attributes.key?(:term) && content.term
              return content.id.to_s if content.class.attributes.key?(:id) && content.id
              return content.name.to_s if content.class.attributes.key?(:name) && content.name
            end

            ''
          end

          # === Helper methods ===

          def build_id_title_attrs(id, title)
            attrs = {}
            attrs[:id] = id if id && !id.to_s.empty?
            attrs[:title] = title if title && !title.to_s.empty?
            attrs
          end

          def find_converter_for_model(model_class)
            Coradoc::Html::Base.find_converter(model_class)
          end

          def find_converter_class_by_name(converter_name)
            klass = Coradoc::Html::Converters.const_get(converter_name, false)
            return klass if klass <= Coradoc::Html::Converters::Base

            nil
          rescue NameError
            nil
          end

          def escape_html(text)
            Coradoc::Html::Base.escape_html(text)
          end

          def escape_attribute(value)
            return '' if value.nil?

            value.to_s.gsub(/&/, '&amp;').gsub(/"/, '&quot;').gsub(/</, '&lt;').gsub(/>/, '&gt;')
          end

          def build_element(tag, content = nil, attributes = {})
            Coradoc::Html::Base.build_element(tag, content, attributes)
          end

          def extract_model_attributes(model)
            Coradoc::Html::Base.extract_attributes(model)
          end

          # === HTML Input Direction (HTML → CoreModel) ===

          def treat_children(node, state = {})
            return [] unless node&.children

            node.children.flat_map do |child|
              convert_node_to_core(child, state)
            end.compact
          end

          def convert_node_to_core(node, state = {})
            case node.type
            when Nokogiri::XML::Node::TEXT_NODE
              text = node.text
              return nil if text.strip.empty? && !state[:preserve_whitespace]

              text
            when Nokogiri::XML::Node::ELEMENT_NODE
              convert_element_to_core(node, state)
            when Nokogiri::XML::Node::COMMENT_NODE
              nil
            end
          end

          def convert_element_to_core(node, state = {})
            if defined?(Coradoc::Html::Input::Converters)
              converter = Coradoc::Html::Input::Converters.lookup(node.name)
              if converter
                result = converter.to_coradoc(node, state)
                return transform_to_coremodel(result) if result
              end
            end

            treat_children(node, state)
          end

          def transform_to_coremodel(model)
            model
          end

          def extract_node_attributes(node)
            return {} unless node.is_a?(Nokogiri::XML::Node)

            node.attributes.each_with_object({}) do |(name, attr), hash|
              hash[name.to_sym] = attr.value
            end
          end

          # Get plain text content from a CoreModel element
          def get_text_content(element)
            return element.to_s unless element.is_a?(Coradoc::CoreModel::Base)

            if element.class.attributes.key?(:text) && element.text
              element.text
            elsif element.class.attributes.key?(:content) && element.content
              element.content.is_a?(String) ? element.content : element.content.to_s
            else
              element.to_s
            end
          end
        end
      end
    end
  end
end
