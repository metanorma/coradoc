# frozen_string_literal: true

module Coradoc
  module Html
    module Theme
      class ModernRenderer
        module Serializers
          # Serialize Coradoc CoreModel to Vue-compatible data structure
          #
          # This module converts the Coradoc CoreModel into a JSON-serializable
          # hash structure that can be consumed by Vue.js components.
          #
          # IMPORTANT: This serializer ONLY handles CoreModel types.
          # All format-specific documents (AsciiDoc, Markdown, etc.) should be
          # transformed to CoreModel before using this serializer.
          module DocumentSerializer
            class << self
              # Serialize document to Vue-compatible format
              #
              # @param document [Coradoc::CoreModel::StructuralElement] Document to serialize
              # @return [Hash] Serialized document data
              # @raise [ArgumentError] if document is not a CoreModel::StructuralElement
              def serialize(document)
                unless document.is_a?(Coradoc::CoreModel::StructuralElement)
                  raise ArgumentError,
                        "Expected CoreModel::StructuralElement, got #{document.class}. " \
                        'Transform your document to CoreModel first using the appropriate ' \
                        'format transformer (e.g., ToCoreModel for your source format).'
                end

                serialize_core_model_document(document)
              end

              # Serialize CoreModel::StructuralElement document
              #
              # @param document [Coradoc::CoreModel::StructuralElement] Document to serialize
              # @return [Hash] Serialized document data
              def serialize_core_model_document(document)
                {
                  id: document.id || generate_uid(document),
                  type: 'document',
                  header: serialize_core_model_header(document),
                  attributes: {},
                  sections: serialize_core_model_children(document.children),
                  toc: build_toc_data_from_core_model(document.children),
                  metadata: {
                    title: document.title || 'Untitled Document',
                    author: nil,
                    revision: nil
                  }
                }
              end

              # Serialize CoreModel header (extracted from title)
              #
              # @param document [Coradoc::CoreModel::StructuralElement] Document
              # @return [Hash, nil] Serialized header
              def serialize_core_model_header(document)
                return nil unless document.title

                {
                  id: generate_uid(document),
                  type: 'header',
                  title: {
                    type: 'title',
                    text: document.title.to_s,
                    level: 1
                  },
                  author: nil
                }
              end

              # Serialize CoreModel children
              #
              # @param children [Array, nil] Children to serialize
              # @return [Array] Serialized children
              def serialize_core_model_children(children)
                return [] unless children

                children.map do |child|
                  serialize_core_model_element(child)
                end.compact
              end

              # Serialize individual CoreModel element
              #
              # @param element [Object] Element to serialize
              # @return [Hash] Serialized element
              def serialize_core_model_element(element)
                case element
                when Coradoc::CoreModel::StructuralElement
                  serialize_core_model_section(element)
                when Coradoc::CoreModel::Block
                  serialize_core_model_block(element)
                when Coradoc::CoreModel::ListBlock
                  serialize_core_model_list(element)
                when Coradoc::CoreModel::Table
                  serialize_core_model_table(element)
                when Coradoc::CoreModel::Image
                  serialize_core_model_image(element)
                when Coradoc::CoreModel::AnnotationBlock
                  serialize_core_model_admonition(element)
                when Coradoc::CoreModel::InlineElement
                  serialize_core_model_inline(element)
                else
                  serialize_generic_element(element)
                end
              end

              # Serialize CoreModel section
              #
              # @param section [Coradoc::CoreModel::StructuralElement] Section to serialize
              # @return [Hash] Serialized section
              def serialize_core_model_section(section)
                level = section.level || 1
                {
                  id: section.id || generate_uid(section),
                  type: 'section',
                  title: section.title ? { type: 'title', text: section.title.to_s, level: level } : nil,
                  level: level,
                  content: [],
                  sections: serialize_core_model_children(section.children)
                }
              end

              # Serialize CoreModel block
              #
              # @param block [Coradoc::CoreModel::Block] Block to serialize
              # @return [Hash] Serialized block
              def serialize_core_model_block(block)
                block_type = case block.element_type
                             when 'paragraph' then 'paragraph'
                             when 'block'
                               case block.delimiter_type
                               when '----' then 'source'
                               when '____' then 'quote'
                               when '====' then 'example'
                               else 'block'
                               end
                             else
                               'block'
                             end

                {
                  id: block.id || generate_uid(block),
                  type: block_type,
                  block_type: block_type,
                  title: block.title,
                  content: serialize_block_content(block),
                  language: block.language
                }
              end

              # Serialize block content
              #
              # @param block [Coradoc::CoreModel::Block] Block to serialize
              # @return [Array] Serialized content
              def serialize_block_content(block)
                return [] unless block.content

                case block.content
                when Array
                  block.content.map { |el| serialize_core_model_element(el) }.compact
                when Coradoc::CoreModel::InlineElement
                  [serialize_core_model_inline(block.content)]
                else
                  [{ type: 'text', content: block.content.to_s }]
                end
              end

              # Serialize CoreModel list
              #
              # @param list [Coradoc::CoreModel::ListBlock] List to serialize
              # @return [Hash] Serialized list
              def serialize_core_model_list(list)
                list_type = case list.marker_type
                            when 'ordered', '1' then 'ordered'
                            when 'unordered', '*', '-' then 'unordered'
                            when 'definition' then 'definition'
                            else 'unordered'
                            end

                {
                  id: generate_uid(list),
                  type: 'list',
                  list_type: list_type,
                  items: (list.items || []).map do |item|
                    serialize_list_item(item)
                  end
                }
              end

              # Serialize list item
              #
              # @param item [Coradoc::CoreModel::ListItem] List item to serialize
              # @return [Hash] Serialized list item
              def serialize_list_item(item)
                content = if item.content
                            case item.content
                            when Array
                              item.content.map { |el| serialize_core_model_element(el) }.compact
                            else
                              [{ type: 'text', content: item.content.to_s }]
                            end
                          else
                            []
                          end

                {
                  id: generate_uid(item),
                  type: 'list_item',
                  content: content
                }
              end

              # Serialize CoreModel table
              #
              # @param table [Coradoc::CoreModel::Table] Table to serialize
              # @return [Hash] Serialized table
              def serialize_core_model_table(table)
                {
                  id: table.id || generate_uid(table),
                  type: 'table',
                  title: nil,
                  rows: (table.rows || []).map do |row|
                    serialize_table_row(row)
                  end
                }
              end

              # Serialize table row
              #
              # @param row [Coradoc::CoreModel::TableRow] Row to serialize
              # @return [Hash] Serialized row
              def serialize_table_row(row)
                {
                  type: 'table_row',
                  header: row.respond_to?(:header) && row.header,
                  cells: (row.cells || []).map do |cell|
                    serialize_table_cell(cell)
                  end
                }
              end

              # Serialize table cell
              #
              # @param cell [Coradoc::CoreModel::TableCell] Cell to serialize
              # @return [Hash] Serialized cell
              def serialize_table_cell(cell)
                content = if cell.content
                            case cell.content
                            when Array
                              cell.content.map { |el| serialize_core_model_element(el) }.compact
                            else
                              cell.content.to_s
                            end
                          else
                            ''
                          end

                {
                  type: 'table_cell',
                  content: content
                }
              end

              # Serialize CoreModel image
              #
              # @param image [Coradoc::CoreModel::Image] Image to serialize
              # @return [Hash] Serialized image
              def serialize_core_model_image(image)
                {
                  type: 'image',
                  src: image.src,
                  alt: image.alt,
                  title: nil,
                  width: image.width,
                  height: image.height,
                  inline: image.inline
                }
              end

              # Serialize CoreModel admonition
              #
              # @param admonition [Coradoc::CoreModel::AnnotationBlock] Admonition to serialize
              # @return [Hash] Serialized admonition
              def serialize_core_model_admonition(admonition)
                {
                  id: generate_uid(admonition),
                  type: 'admonition',
                  style: admonition.annotation_type || :note,
                  content: admonition.content ? [{ type: 'text', content: admonition.content.to_s }] : []
                }
              end

              # Serialize CoreModel inline element
              #
              # @param element [Coradoc::CoreModel::InlineElement] Inline element to serialize
              # @return [Hash] Serialized inline element
              def serialize_core_model_inline(element)
                element_type = case element.inline_type
                               when 'bold' then 'bold'
                               when 'italic' then 'italic'
                               when 'monospace' then 'monospace'
                               when 'link' then 'link'
                               when 'xref' then 'xref'
                               when 'highlight' then 'highlight'
                               when 'strikethrough' then 'strikethrough'
                               when 'underline' then 'underline'
                               when 'subscript' then 'subscript'
                               when 'superscript' then 'superscript'
                               else 'inline'
                               end

                result = {
                  type: element_type,
                  content: element.text.to_s
                }

                # Add link-specific attributes
                result[:href] = element.target if element.inline_type == 'link' && element.respond_to?(:target)

                # Add cross-ref specific attributes
                result[:target] = element.target if element.inline_type == 'xref' && element.respond_to?(:target)

                result
              end

              # Build TOC data from CoreModel children
              #
              # @param children [Array] Children to process
              # @param level [Integer] Current level
              # @return [Array] TOC entries
              def build_toc_data_from_core_model(children, level = 1)
                return [] unless children

                children.each_with_object([]) do |child, result|
                  next unless child.is_a?(Coradoc::CoreModel::StructuralElement)

                  entry = {
                    id: child.id || generate_uid(child),
                    title: child.title.to_s,
                    level: level,
                    children: build_toc_data_from_core_model(child.children, level + 1)
                  }

                  result << entry
                end
              end

              # Serialize generic element (fallback for unknown types)
              #
              # @param element [Object] Element to serialize
              # @return [Hash] Serialized element
              def serialize_generic_element(element)
                text_content = case element
                               when String
                                 element
                               else
                                 str = element.to_s
                                 str.include?('#<') ? '' : str
                               end

                {
                  type: 'generic',
                  class: element.class.name,
                  content: text_content
                }
              end

              private

              # Generate unique ID for object
              #
              # @param object [Object] Object to generate ID for
              # @return [String] Unique ID
              def generate_uid(object)
                object.object_id.to_s(36)
              end
            end
          end
        end
      end
    end
  end
end
