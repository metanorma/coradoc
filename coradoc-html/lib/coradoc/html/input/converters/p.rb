# frozen_string_literal: true

module Coradoc
  module Input
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

            content.each do |item|
              next unless item.is_a?(Coradoc::CoreModel::InlineElement)
              next unless item.content.is_a?(String)

              item.content = item.content.gsub(/\A　+|　+\z/, '')
            end

            strip_edge_whitespace(content)
            reject_empty_elements(content)
          end

          def strip_edge_whitespace(content)
            first = content.find { |item| text_element?(item) }
            strip_left(first) if first

            last = content.reverse.find { |item| text_element?(item) }
            strip_right(last) if last
          end

          def strip_left(item)
            case item
            when Coradoc::CoreModel::InlineElement
              item.content = item.content.lstrip if item.content.is_a?(String)
            when String
              item.replace(item.lstrip)
            end
          end

          def strip_right(item)
            case item
            when Coradoc::CoreModel::InlineElement
              item.content = item.content.rstrip if item.content.is_a?(String)
            when String
              item.replace(item.rstrip)
            end
          end

          def text_element?(item)
            item.is_a?(Coradoc::CoreModel::InlineElement) || item.is_a?(String)
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
end
