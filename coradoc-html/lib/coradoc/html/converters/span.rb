# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for generic Span inline element
      class Span < Base
        class << self
          # Convert HTML <span> to CoreModel::InlineElement
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] Span inline element
          def to_coradoc(node, state = {})
            text = node.inner_text
            attrs = extract_node_attributes(node)

            # Collect all children for potential mixed content
            children = node.children.flat_map do |child|
              convert_node_to_core(child, state)
            end.compact

            span = Coradoc::CoreModel::InlineElement.new(
              format_type: 'span',
              content: text
            )

            # Set class from attributes as metadata
            span.set_metadata(:class, attrs[:class]) if attrs[:class]

            # If there are children (mixed content), use them
            span.instance_variable_set(:@children, children) if children.any?

            span
          end

          # Convert CoreModel::InlineElement (span) to HTML <span>
          # @param model [Coradoc::CoreModel::InlineElement] Span model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            # Prefer children for mixed content, fall back to content
            content = if model.respond_to?(:children) && model.children&.any?
                        model.children.map { |c| convert_content_to_html(c, state) }.join
                      else
                        escape_html(model.content || '')
                      end

            # Build attributes from metadata
            attrs = {}
            if model.respond_to?(:metadata) && model.metadata && model.metadata[:class]
              attrs[:class] =
                model.metadata[:class]
            end

            build_element('span', content, attrs)
          end
        end
      end
    end
  end
end
