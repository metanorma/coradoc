# frozen_string_literal: true

require_relative 'angle'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Autolink
          # GFM bare-URL autolink: https://example.com (no brackets).
          # Supported by GFM and most modern renderers; minimal noise.
          class Bare < Angle
            class << self
              def render(url, _text, _ctx)
                url.to_s
              end
            end
          end
        end
      end
    end
  end
end
