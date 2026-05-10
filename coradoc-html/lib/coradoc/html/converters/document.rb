# frozen_string_literal: true

require 'coradoc/html/node_builder'

module Coradoc
  module Html
    module Converters
      class Document < Base
        class << self
          # Convert HTML document to CoreModel::StructuralElement
          def to_coradoc(node, state = {})
            body = find_body_content(node)
            metadata = extract_metadata(node, state)
            content = treat_children(body, state)

            doc = Coradoc::CoreModel::StructuralElement.new(
              element_type: 'document',
              title: metadata[:title],
              children: content
            )
            doc.metadata = (doc.metadata || {}).merge(author: metadata[:author]) if metadata[:author]
            doc
          end

          # Convert CoreModel::StructuralElement to HTML
          def to_html(model, state = {})
            return convert_core_model_document(model, state) if model.is_a?(Coradoc::CoreModel::StructuralElement)

            ''
          end

          def convert_core_model_document(model, state = {})
            children = []

            if model.title
              title_text = model.title.is_a?(String) ? model.title : model.title.to_s
              children << NodeBuilder.build(:h1, title_text) unless title_text.empty?
            end

            model.children&.each do |child|
              html = convert_content_to_html(child, state)
              children << html if html && !html.empty?
            end

            attrs = { id: 'content' }
            attrs[:id] = model.id if model.id
            NodeBuilder.build(:article, children, **attrs).to_html
          end

          private

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

          def extract_metadata(node, _state)
            metadata = { attributes: {} }

            if node.is_a?(Nokogiri::XML::Document) || node.is_a?(Nokogiri::XML::Node)
              title_node = node.at('title') || node.at('h1')
              metadata[:title] = title_node.text.strip if title_node

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
