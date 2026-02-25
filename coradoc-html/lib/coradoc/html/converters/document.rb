# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Document
      class Document < Base
        class << self
          # Convert HTML document to CoreModel::StructuralElement
          # @param node [Nokogiri::XML::Document, Nokogiri::XML::Node] HTML document or article node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::StructuralElement] Document model
          def to_coradoc(node, state = {})
            # Find the main content area
            body = find_body_content(node)

            # Extract document metadata
            metadata = extract_metadata(node, state)

            # Process body content
            content = treat_children(body, state)

            # Create document
            doc = Coradoc::CoreModel::StructuralElement.new(
              element_type: 'document',
              title: metadata[:title],
              children: content
            )

            # Store author in metadata if present
            doc.metadata = (doc.metadata || {}).merge(author: metadata[:author]) if metadata[:author]

            doc
          end

          # Convert CoreModel::StructuralElement to HTML
          # @param model [Coradoc::CoreModel::StructuralElement] Document model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            # Handle CoreModel::StructuralElement
            return convert_core_model_document(model, state) if model.is_a?(Coradoc::CoreModel::StructuralElement)

            # Fallback for other types
            ''
          end

          # Convert CoreModel::StructuralElement to HTML
          # @param model [Coradoc::CoreModel::StructuralElement] CoreModel document
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def convert_core_model_document(model, state = {})
            parts = []

            # Add title if present
            if model.title
              title_text = model.title.is_a?(String) ? model.title : model.title.to_s
              parts << build_element('h1', title_text) unless title_text.empty?
            end

            # Convert children
            model.children&.each do |child|
              html = convert_content_to_html(child, state)
              parts << html if html && !html.empty?
            end

            # Wrap in article tag with id="content" for CSS styling
            content = parts.join("\n")
            attributes = { id: 'content' }
            attributes[:id] = model.id if model.id
            build_element('article', content, attributes)
          end

          private

          # Find the body content in HTML document
          def find_body_content(node)
            case node
            when Nokogiri::HTML::Document
              node.at('body') || node.at('article') || node.root
            when Nokogiri::XML::Document
              node.at('body') || node.at('article') || node.root
            else
              node
            end
          end

          # Extract document metadata from HTML
          def extract_metadata(node, _state)
            metadata = { attributes: {} }

            # Extract title from <title> or <h1> (node is Nokogiri::XML::Node or Document)
            if node.is_a?(Nokogiri::XML::Document) || node.is_a?(Nokogiri::XML::Node)
              title_node = node.at('title') || node.at('h1')
              metadata[:title] = title_node.text.strip if title_node

              # Extract author from meta tag
              author_meta = node.at('meta[name="author"]')
              metadata[:author] = author_meta['content'] if author_meta
            end

            metadata
          end
        end
      end
    end
  end
end
