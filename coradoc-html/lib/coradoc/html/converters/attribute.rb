# frozen_string_literal: true

require 'nokogiri'

module Coradoc
  module Html
    module Converters
      class Attribute
        def self.to_html(model, _options = {})
          key = escape_html(model.metadata&.dig(:key).to_s)

          values = Array(model.metadata&.dig(:value)).compact

          comment_text = if values.empty?
                           ":#{key}:"
                         else
                           value_str = values.map { |v| escape_html(v.to_s) }.join(', ')
                           ":#{key}: #{value_str}"
                         end

          doc = Nokogiri::HTML::DocumentFragment.parse('')
          comment = Nokogiri::XML::Comment.new(doc, " #{comment_text} ")
          doc.add_child(comment)
          doc.to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.is_a?(Nokogiri::XML::Comment)

          content = element.content.strip

          return nil unless content.match?(/^:([^:]+):(.*)$/)

          match = content.match(/^:([^:]+):(.*)$/)
          key = match[1].strip
          value_part = match[2].strip

          values = value_part.empty? ? [] : value_part.split(',').map(&:strip)

          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'attribute',
            content: key,
            metadata: {
              key: key,
              value: values
            }
          )
        end
      end
    end
  end
end
