# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for include directives
      class Include < Base
        # Convert CoreModel::Block (include) to HTML comment with include directive
        # Note: HTML doesn't have native include support, so we use a comment
        def self.to_html(include_directive, _options = {})
          return '' unless include_directive

          # Get include path from metadata
          path = include_directive.metadata&.dig(:path) || ''
          path = escape_html(path)

          # Build include directive as comment
          comment_text = "include::#{path}[]"

          # Add attributes if present
          attrs = include_directive.metadata&.dig(:attributes) || {}
          if attrs && !attrs.empty?
            attrs_str = attrs.map { |k, v| "#{k}=#{v}" }.join(',')
            comment_text = "include::#{path}[#{attrs_str}]" unless attrs_str.empty?
          end

          "<!-- #{comment_text} -->"
        end

        # Convert HTML comment with include directive to CoreModel::Block (include)
        def self.to_coradoc(element, _options = {})
          return nil unless element.comment?

          # Check if comment contains include directive
          text = element.text.to_s.strip
          return nil unless text.match?(/^include::/)

          # Parse include directive
          # Format: include::path[attributes]
          return unless text =~ /^include::([^\[]+)(\[([^\]]*)\])?/

          path = ::Regexp.last_match(1).strip
          attrs_str = ::Regexp.last_match(3)

          attrs = {}
          if attrs_str && !attrs_str.empty?
            # Parse attributes (simplified - doesn't handle complex cases)
            attrs_str.split(',').each do |attr|
              if attr.include?('=')
                k, v = attr.split('=', 2)
                attrs[k.strip.to_sym] = v.strip
              end
            end
          end

          Coradoc::CoreModel::Block.new(
            element_type: 'include',
            content: path,
            metadata: {
              path: path,
              attributes: attrs
            }
          )
        end
      end
    end
  end
end
