# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        # Example blocks emit an HTML fallback that preserves the caption
        # as a heading inside `<div class="example">`.
        #
        # When `admonition_style == :container` (VitePress), emits
        # `:::details Caption\n... \n:::` instead.
        class ExampleBlock < ElementSerializer
          handles_type ::Coradoc::Markdown::ExampleBlock

          def call(element, ctx)
            body = render_body(element, ctx)
            if ctx.config.admonition_style == :container
              render_container(element, body)
            else
              render_html(element, body)
            end
          end

          private

          def render_body(element, ctx)
            return element.content.to_s if element.children.nil? || element.children.empty?

            element.children.map { |c| ctx.serialize(c) }.join("\n\n")
          end

          def render_html(element, body)
            caption_html = element.caption ? %(<h4>Example: #{element.caption}</h4>\n) : ''
            inner = element.children&.any? ? body : "<p>#{body}</p>"
            %(<div class="example">\n#{caption_html}#{inner}\n</div>)
          end

          def render_container(element, body)
            title = element.caption ? " Example: #{element.caption}" : ''
            ":::details#{title}\n#{body}\n:::"
          end
        end
      end
    end
  end
end
