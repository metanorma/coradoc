# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class P < Base
        INSTANCE = new

        def to_coradoc(node, state = {})
          id = node['id']
          content = treat_children_coradoc(node, state)

          content = strip_fullwidth_spaces(content)

          Coradoc::CoreModel::ParagraphBlock.new(
            children: content,
            id: id
          )
        end

        private

        def strip_fullwidth_spaces(content)
          return content unless content.is_a?(Array)

          content = strip_fullwidth_per_element(content)
          content = Coradoc::CoreModel::InlineContent.strip_edges(content)
          reject_empty_elements(content)
        end

        # Strip CJK fullwidth spaces from the leading/trailing edge of
        # every InlineElement's content. Returns a new array; inputs
        # are not mutated.
        def strip_fullwidth_per_element(content)
          content.map do |item|
            next item unless item.is_a?(Coradoc::CoreModel::InlineElement)
            next item unless item.content.is_a?(String)

            item.with_content(item.content.gsub(/\A　+|　+\z/, ''))
          end
        end

        def reject_empty_elements(content)
          content.reject do |item|
            if item.is_a?(Coradoc::CoreModel::InlineElement)
              item.content.to_s.empty? && !has_nested_content?(item)
            elsif item.is_a?(String)
              item.empty?
            else
              false
            end
          end
        end

        def has_nested_content?(item)
          item.is_a?(Coradoc::CoreModel::InlineElement) &&
            item.nested_elements && !item.nested_elements.empty?
        end
      end

      register :p, P::INSTANCE
    end
  end
end
