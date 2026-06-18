# frozen_string_literal: true

require_relative 'base'
require_relative 'angle'
require_relative 'bare'
require_relative 'none'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Autolink
          # Resolves an autolink strategy from a Config + (url, text).
          #
          # Mode lookup:
          #   autolinks == true  → Angle (default, CommonMark-safe)
          #   autolinks == false → None (use standard link syntax)
          #
          # The angle form is preferred over bare because angle brackets
          # disambiguate the URL in flowing text and render identically
          # across HTML-aware Markdown processors.
          #
          # Use `Bare` explicitly for GFM-targeted output where minimal
          # noise is preferred.
          module Registry
            MODES = {
              angle: Angle,
              bare: Bare,
              none: None
            }.freeze

            class << self
              def lookup(mode)
                MODES.fetch(mode.to_sym) do
                  raise ArgumentError, "Unknown autolink mode: #{mode.inspect}. " \
                                       "Known: #{MODES.keys.inspect}"
                end
              end

              def resolve(url:, text:, ctx:)
                mode = ctx.config.autolinks ? :angle : :none
                strategy = lookup(mode)
                return nil unless strategy.applies?(url, text, ctx)

                strategy
              end

              def render_or_default(url:, text:, ctx:, default:)
                strategy = resolve(url: url, text: text, ctx: ctx)
                strategy ? strategy.render(url, text, ctx) : default
              end
            end
          end
        end
      end
    end
  end
end
