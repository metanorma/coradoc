# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Admonition
          # Container syntax (VitePress, markdown-it-container):
          #
          #   :::note
          #   content
          #   :::
          #
          # Custom title:
          #
          #   :::note[Custom Title]
          #   content
          #   :::
          class Container < Base
            class << self
              def render(admonition, _ctx)
                type = admonition.admonition_type.to_s
                title_suffix = admonition.title ? "[#{admonition.title}]" : ''
                ":::#{type}#{title_suffix}\n#{admonition.content.to_s}\n:::"
              end
            end
          end
        end
      end
    end
  end
end
