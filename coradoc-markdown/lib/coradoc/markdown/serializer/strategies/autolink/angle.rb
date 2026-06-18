# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Autolink
          # CommonMark angle-bracket autolink: <https://example.com>
          # Renders identically across all HTML-aware renderers.
          class Angle < Base
            class << self
              def applies?(url, text, ctx)
                ctx.config.autolinks && url_eql_text?(url, text)
              end

              def render(url, _text, _ctx)
                "<#{url}>"
              end

              private

              def url_eql_text?(url, text)
                return false unless url && text

                url.to_s.strip == text.to_s.strip
              end
            end
          end
        end
      end
    end
  end
end
