# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Sub < Base
          def to_coradoc(node, state = {})
            leading_whitespace, trailing_whitespace = extract_leading_trailing_whitespace(node)

            content = treat_children_coradoc(node, state)

            # Check if content is empty
            return nil if content_empty?(content)

            # Create CoreModel::InlineElement with format_type "subscript"
            e = Coradoc::CoreModel::InlineElement.new(
              format_type: 'subscript',
              content: content
            )
            result = [leading_whitespace, e, trailing_whitespace].compact
            result.length == 1 ? result.first : result
          end

          private

          def content_empty?(content)
            return true if content.nil?
            return content.strip.empty? if content.is_a?(String)
            return content.empty? if content.is_a?(Array)

            false
          end
        end

        register :sub, Sub.new
      end
    end
  end
end
