# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Pure-function module for normalizing raw parser `:attribute_list`
      # values into a single canonical Model::AttributeList.
      #
      # The parser's `block_header` rule captures every consecutive `[...]`
      # block before a structural element as a Parslet sequence under
      # `:attribute_list`. Real-world AsciiDoc often stacks multiple lists
      # before a single delimiter:
      #
      #   [role=quote]
      #   [source, ruby]
      #   ----
      #   code
      #   ----
      #
      # This module is the single source of truth for converting any of those
      # shapes (nil, single list, array of lists, array of hashes) into one
      # canonical AttributeList that downstream model constructors can use.
      module AttributeListNormalizer
        module_function

        # @param value [Object, nil] Raw parser value bound to :attribute_list
        # @return [Model::AttributeList, nil]
        def coerce(value)
          case value
          when nil then nil
          when Model::AttributeList then value
          when Array
            lists = value.map { |entry| unwrap(entry) }.compact
            return nil if lists.empty?
            return lists.first if lists.size == 1

            merge(lists)
          else
            value
          end
        end

        # Merge several AttributeLists into one, preserving positional order
        # and concatenating named keys in input order.
        # @param lists [Array<Model::AttributeList>]
        # @return [Model::AttributeList]
        def merge(lists)
          merged = Model::AttributeList.new
          lists.each do |list|
            next unless list.is_a?(Model::AttributeList)

            list.positional.each { |p| merged.add_positional(p.value) }
            list.named.each { |n| merged.add_named(n.name, n.value) }
          end
          merged
        end

        # Unwrap a single entry of the parser's :attribute_list sequence.
        # @param entry [Object]
        # @return [Model::AttributeList, nil]
        def unwrap(entry)
          return entry if entry.is_a?(Model::AttributeList)

          entry[:attribute_list] if entry.is_a?(Hash) && entry.key?(:attribute_list)
        end
      end
    end
  end
end
