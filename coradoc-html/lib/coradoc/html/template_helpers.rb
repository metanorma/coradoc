# frozen_string_literal: true

require 'liquid'
require_relative 'escape'

module Coradoc
  module Html
    # Liquid filters for template rendering
    module TemplateFilters
      # Render a CoreModel element or Drop by looking up its template.
      #
      # Usage in templates:
      #   {{ child | render_element }}
      #   {% for item in children %}{{ item | render_element }}{% endfor %}
      #
      def render_element(input)
        return '' if input.nil?

        renderer = @context.registers[:renderer]
        return '' unless renderer

        case input
        when Drop::Base
          renderer.render_drop(input)
        when Array
          input.map { |i| render_element(i) }.join("\n")
        when Hash
          render_hash_data(input, renderer)
        when String
          input
        else
          drop = Drop::DropFactory.create(input)
          drop.is_a?(Drop::Base) ? renderer.render_drop(drop) : drop.to_s
        end
      end

      def escape_html(input)
        Escape.escape_html(input)
      end

      # Escape HTML attribute values
      def escape_attr(input)
        Escape.escape_attr(input)
      end

      # JSON-encode with </script protection for inline JS
      def safe_json(input)
        Escape.safe_json(input)
      end

      private

      def render_hash_data(data, renderer)
        drop_type = data['drop_type']
        return data.to_s unless drop_type

        template = renderer.find_template(drop_type)
        return data.to_s unless template

        template.render(data, registers: { renderer: renderer }).strip
      end
    end
  end
end

# Register filters with Liquid
Liquid::Environment.default.register_filter(Coradoc::Html::TemplateFilters)
