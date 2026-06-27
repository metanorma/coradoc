# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Operations on mixed arrays of inline content (String /
    # InlineElement / CoreModel::Base). Single source of truth for text
    # extraction and edge cleanup, replacing parallel implementations
    # that previously lived in the HTML converters.
    #
    # No method here mutates its inputs — InlineElements are duplicated
    # via #with_content, Strings are replaced with new instances.
    module InlineContent
      class << self
        # Extract plain text from a mixed content value.
        #
        # nil → '' / String → itself / Array → text_of mapped + joined /
        # InlineElement → #content.to_s / StructuralElement → recurse on
        # #children / other Base → #content if String else #title.to_s /
        # anything else → #to_s.
        def text_of(content)
          return '' if content.nil?
          return content if content.is_a?(String)
          return text_of_one(content) unless content.is_a?(Array)

          content.map { |item| text_of_one(item) }.join
        end

        # Return a new array with leading whitespace stripped from the
        # first text-carrying item and trailing whitespace stripped from
        # the last. Inputs are not mutated. Non-Array inputs return
        # unchanged. If no item carries text, returns the input array
        # unchanged.
        def strip_edges(content)
          return content unless content.is_a?(Array)
          return content if content.empty?

          first_idx = content.index { |i| text_carrier?(i) }
          return content if first_idx.nil?
          last_idx = content.rindex { |i| text_carrier?(i) }

          content.map.with_index do |item, idx|
            next item unless text_carrier?(item)

            stripped = item_text(item)
            stripped = stripped.lstrip if idx == first_idx
            stripped = stripped.rstrip if idx == last_idx
            item.is_a?(String) ? stripped : item.with_content(stripped)
          end
        end

        private

        def text_of_one(item)
          case item
          when String then item
          when CoreModel::InlineElement then item.content.to_s
          when CoreModel::StructuralElement then text_of(Array(item.children))
          when CoreModel::Block
            item.children.is_a?(Array) && !item.children.empty? ? text_of(item.children) : item.content.to_s
          when CoreModel::Base
            item.content.is_a?(String) ? item.content : item.title.to_s
          else
            item.to_s
          end
        end

        def text_carrier?(item)
          item.is_a?(String) || item.is_a?(CoreModel::InlineElement)
        end

        def item_text(item)
          item.is_a?(String) ? item : item.content.to_s
        end
      end
    end
  end
end
