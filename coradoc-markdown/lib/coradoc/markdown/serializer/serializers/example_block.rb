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
            if ctx.config.admonition_style == :container
              render_container(element)
            else
              render_html(element)
            end
          end

          private

          def render_html(element)
            caption_html = element.caption ? %(<h4>Example: #{element.caption}</h4>\n) : ''
            %(<div class="example">\n#{caption_html}<p>#{element.content.to_s}</p>\n</div>)
          end

          def render_container(element)
            title = element.caption ? " Example: #{element.caption}" : ''
            ":::details#{title}\n#{element.content.to_s}\n:::"
          end
        end
      end
    end
  end
end
