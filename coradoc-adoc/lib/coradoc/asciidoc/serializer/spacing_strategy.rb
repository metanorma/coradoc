# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      # Handles spacing logic for AsciiDoc serialization.
      # Determines appropriate spacing between different element types.
      class SpacingStrategy
        class << self
          # Apply spacing to elements based on their types
          # @param elements [Array] Elements to add spacing between
          # @param options [Hash] Spacing options
          # @return [String] Elements with appropriate spacing
          def apply(elements, _options = {})
            return '' if elements.nil? || elements.empty?
            return elements.first.to_s if elements.size == 1

            result = []
            elements.each_with_index do |element, index|
              result << element.to_s

              # Add spacing between current and next element
              next unless index < elements.size - 1

              next_element = elements[index + 1]
              spacing = spacing_between(element, next_element)
              result << spacing if spacing
            end

            result.join
          end

          # Determine spacing between two elements
          # @param current [Object] Current element
          # @param next_elem [Object] Next element
          # @return [String, nil] Spacing string or nil
          def spacing_between(current, next_elem)
            # Block-level elements typically need double newline spacing
            if block_level?(current) && block_level?(next_elem)
              "\n\n"
            # Inline elements don't need extra spacing
            elsif inline_level?(current) && inline_level?(next_elem)
              nil
            # Mixed block/inline needs single newline
            elsif block_level?(current) || block_level?(next_elem)
              "\n"
            end
          end

          # Check if element is block-level
          # @param element [Object] Element to check
          # @return [Boolean] True if block-level
          def block_level?(element)
            return false if element.nil?

            element.is_a?(Coradoc::AsciiDoc::Model::Block::Core) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Section) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Paragraph) ||
              element.is_a?(Coradoc::AsciiDoc::Model::List) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Table) ||
              element.is_a?(Coradoc::AsciiDoc::Model::CommentBlock) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Admonition)
          end

          # Check if element is inline-level
          # @param element [Object] Element to check
          # @return [Boolean] True if inline-level
          def inline_level?(element)
            return false if element.nil?

            element.is_a?(String) ||
              element.is_a?(Coradoc::AsciiDoc::Model::TextElement) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Inline::Bold) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Inline::Italic) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Inline::Monospace) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Inline::Highlight) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Inline::Superscript) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Inline::Subscript)
          end
        end
      end
    end
  end
end
