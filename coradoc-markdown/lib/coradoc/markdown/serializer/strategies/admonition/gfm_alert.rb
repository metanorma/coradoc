# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Admonition
          # GFM Alerts (native since Dec 2023): `> [!TYPE]\n> content`.
          # Recognized types: NOTE, TIP, IMPORTANT, WARNING, CAUTION.
          # Source: https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts
          class GfmAlert < Base
            class << self
              def render(admonition, ctx)
                type = admonition.admonition_type.to_s.capitalize
                body = render_body(admonition, ctx)
                body = body.lines.map { |line| "> #{line}".rstrip }.join("\n")
                title_suffix = admonition.title ? " \"#{admonition.title}\"" : ''
                "> [!#{type}]#{title_suffix}\n#{body}"
              end
            end
          end
        end
      end
    end
  end
end
