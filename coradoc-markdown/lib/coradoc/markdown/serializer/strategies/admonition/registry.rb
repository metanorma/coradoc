# frozen_string_literal: true

require_relative 'base'
require_relative 'github'
require_relative 'gfm_alert'
require_relative 'container'
require_relative 'html'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Admonition
          # Resolves the active admonition strategy from `config.admonition_style`.
          #
          # Modes:
          #   :github    → > **NOTE:** text         (broad compat — DEFAULT for :gfm)
          #   :gfm_alert → > [!NOTE]\n> text         (GFM native since 2024)
          #   :container → :::note\n... \n:::         (VitePress / markdown-it)
          #   :html      → <div class="note">...</div>
          module Registry
            MODES = {
              github: Github,
              gfm_alert: GfmAlert,
              container: Container,
              html: Html
            }.freeze

            class << self
              def lookup(mode)
                MODES.fetch(mode.to_sym) do
                  raise ArgumentError, "Unknown admonition mode: #{mode.inspect}. " \
                                       "Known: #{MODES.keys.inspect}"
                end
              end

              def resolve(ctx:)
                lookup(ctx.config.admonition_style)
              end

              def render(admonition, ctx:)
                resolve(ctx: ctx).render(admonition, ctx)
              end
            end
          end
        end
      end
    end
  end
end
