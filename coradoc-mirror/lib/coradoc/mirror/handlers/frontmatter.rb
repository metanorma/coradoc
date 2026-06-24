# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      # Handles FrontmatterBlock → frontmatter node.
      #
      # Walks the CoreModel +data+ hash and builds a typed tree of
      # FrontmatterEntry / FrontmatterValue nodes. Dates/times are ISO
      # 8601-encoded so the wire shape is JSON-native.
      module Frontmatter
        def self.call(element, *)
          entries = build_entries(element.data || {})

          Node::Frontmatter.new(
            attrs: Node::Frontmatter::Attrs.new(
              schema: element.schema,
              entries: entries
            )
          )
        end

        class << self
          private

          def build_entries(data)
            data.map { |key, value| build_entry(key.to_s, value) }
          end

          def build_entry(key, value)
            Node::FrontmatterEntry.new(
              key: key,
              value: build_value(value)
            )
          end

          def build_value(value)
            case value
            when Hash
              Node::FrontmatterValue.new(
                value_type: 'map',
                entries: build_entries(value)
              )
            when Array
              Node::FrontmatterValue.new(
                value_type: 'array',
                items: value.map { |v| build_value(v) }
              )
            when Integer
              Node::FrontmatterValue.new(value_type: 'integer', integer_value: value)
            when Float
              Node::FrontmatterValue.new(value_type: 'float', float_value: value)
            when TrueClass, FalseClass
              Node::FrontmatterValue.new(value_type: 'boolean', boolean_value: value)
            when Date, DateTime
              Node::FrontmatterValue.new(value_type: 'date', date_value: value)
            when Time
              Node::FrontmatterValue.new(value_type: 'datetime', datetime_value: value)
            when Symbol
              Node::FrontmatterValue.new(value_type: 'symbol', symbol_value: value.to_s)
            when nil
              Node::FrontmatterValue.new(value_type: 'nil')
            else
              Node::FrontmatterValue.new(value_type: 'string', string_value: value.to_s)
            end
          end
        end
      end
    end
  end
end
