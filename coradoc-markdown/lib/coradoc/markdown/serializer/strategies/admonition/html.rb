# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Admonition
          # HTML fallback: a div with `class="<type>"` and optional
          # `<div class="title">` for the title.
          class Html < Base
            class << self
              def render(admonition, ctx)
                type = admonition.admonition_type.to_s
                title_html = admonition.title ? %(<div class="title">#{admonition.title}</div>\n) : ''
                %(<div class="#{type}">\n#{title_html}#{render_body(admonition, ctx)}\n</div>)
              end
            end
          end
        end
      end
    end
  end
end
