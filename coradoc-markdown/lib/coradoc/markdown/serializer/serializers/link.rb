# frozen_string_literal: true

require_relative '../element_serializer'
require_relative '../strategies/autolink/registry'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Link < ElementSerializer
          handles_type ::Coradoc::Markdown::Link

          def call(element, ctx)
            url = element.url.to_s
            text = element.text.to_s
            title_suffix = element.title ? " \"#{element.title}\"" : ''

            Strategies::Autolink::Registry.render_or_default(
              url: url,
              text: text,
              ctx: ctx,
              default: "[#{text}](#{url}#{title_suffix})"
            )
          end
        end
      end
    end
  end
end
