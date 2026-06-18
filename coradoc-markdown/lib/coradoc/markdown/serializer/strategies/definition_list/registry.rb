# frozen_string_literal: true

require_relative 'base'
require_relative 'flat'
require_relative 'nested_html'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module DefinitionList
          # Picks the right strategy for a given list:
          #
          #   1. If no item has nesting → Flat (PHP Markdown Extra)
          #   2. If any item has nesting → NestedHtml (HTML fallback)
          #   3. If config says :flatten and list has nesting → Flat
          #      (drops nesting — explicit information-loss opt-in)
          module Registry
            STRATEGIES = [NestedHtml, Flat].freeze

            class << self
              def resolve(list, ctx)
                return Flat if ctx.config.definition_list_nested == :flatten

                STRATEGIES.find { |s| s.applies?(list, ctx) } || Flat
              end

              def render(list, ctx)
                resolve(list, ctx).render(list, ctx)
              end
            end
          end
        end
      end
    end
  end
end
