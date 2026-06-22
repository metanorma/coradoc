# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Admonition
          # GitHub-style: a styled blockquote with `**TYPE:**` prefix.
          # Renders correctly in GitHub, GitLab, and most renderers that
          # recognize the bold-prefix pattern.
          class Github < Base
            class << self
              def render(admonition, ctx)
                type = admonition.admonition_type.to_s.upcase
                body = render_body(admonition, ctx)
                if admonition.title
                  body = "**#{admonition.title}**\n\n#{body}" unless admonition.title.to_s.strip.empty?
                end
                "> **#{type}:** #{body}"
              end
            end
          end
        end
      end
    end
  end
end
