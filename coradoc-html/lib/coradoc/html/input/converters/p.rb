# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class P < Base
          def to_coradoc(node, state = {})
            id = node['id']
            content = treat_children_coradoc(node, state)

            # Strip full-width spaces from paragraph content
            content = strip_fullwidth_spaces(content)

            Coradoc::CoreModel::Block.new(
              delimiter_type: 'paragraph',
              children: content,
              id: id
            )
          end

          private

          def strip_fullwidth_spaces(content)
            return content unless content.is_a?(Array)

            # Strip full-width spaces from all inline elements
            content.each do |item|
              if item.is_a?(Coradoc::CoreModel::InlineElement) && item.content.is_a?(String)
                item.content = item.content.gsub(/\A　+|　+\z/, '')
              elsif item.is_a?(String)
                item.gsub(/\A　+|　+\z/, '')
              end
            end

            # Strip leading space from first text element
            first_text = content.find { |item| item.is_a?(Coradoc::CoreModel::InlineElement) || item.is_a?(String) }
            if first_text.is_a?(Coradoc::CoreModel::InlineElement) && first_text.content.is_a?(String)
              first_text.content = first_text.content.lstrip
            elsif first_text.is_a?(String)
              first_text.lstrip
            end

            # Strip trailing space from last text element
            last_text = content.reverse.find do |item|
              item.is_a?(Coradoc::CoreModel::InlineElement) || item.is_a?(String)
            end
            if last_text.is_a?(Coradoc::CoreModel::InlineElement) && last_text.content.is_a?(String)
              last_text.content = last_text.content.rstrip
            elsif last_text.is_a?(String)
              last_text.rstrip
            end

            # Remove empty text elements after stripping
            # But keep InlineElements that have nested_elements (e.g., bold with nested text)
            content.reject do |item|
              if item.is_a?(Coradoc::CoreModel::InlineElement)
                item.content.to_s.empty? && !item_has_nested_content?(item)
              elsif item.is_a?(String)
                item.empty?
              else
                false
              end
            end
          end

          # Check if InlineElement has meaningful nested content
          def item_has_nested_content?(item)
            return false unless item.respond_to?(:nested_elements)
            return false if item.nested_elements.nil? || item.nested_elements.empty?

            true
          end
        end

        register :p, P.new
      end
    end
  end
end
