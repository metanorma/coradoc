# frozen_string_literal: true

require 'liquid'

module Coradoc
  module Html
    # Liquid filters for template rendering
    module TemplateFilters
      # Render a CoreModel element by looking up its template
      #
      # Usage in templates:
      #   {{ child | render_element }}
      #   {% for item in children %}{{ item | render_element }}{% endfor %}
      #
      def render_element(input, renderer = nil)
        return '' if input.nil?
        return input.map { |i| render_element(i, renderer) }.join("\n") if input.is_a?(Array)

        # Get the renderer from context registers
        renderer ||= @context.registers[:renderer]

        # If input is a Liquid::Drop, extract the original model object.
        # Liquid::Drop stores the wrapped object as @object with no public
        # reader — this is the only way to unwrap it.
        original = if input.is_a?(::Liquid::Drop)
                     input.instance_variable_get(:@object)
                   else
                     input
                   end

        # Renderer is always a Coradoc::Html::Renderer which has a render method
        renderer.render(original)
      end

      # Escape HTML entities
      def escape_html(input)
        input.to_s
             .gsub(/&/, '&amp;')
             .gsub(/</, '&lt;')
             .gsub(/>/, '&gt;')
             .gsub(/"/, '&quot;')
             .gsub(/'/, '&#39;')
      end

      # Escape HTML attribute values
      def escape_attr(input)
        input.to_s
             .gsub(/&/, '&amp;')
             .gsub(/"/, '&quot;')
             .gsub(/</, '&lt;')
             .gsub(/>/, '&gt;')
      end
    end
  end
end

# Register filters with Liquid (using the non-deprecated API)
Liquid::Environment.default.register_filter(Coradoc::Html::TemplateFilters)
