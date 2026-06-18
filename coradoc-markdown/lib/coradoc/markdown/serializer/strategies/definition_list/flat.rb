# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module DefinitionList
          # PHP Markdown Extra flat syntax:
          #
          #   term
          #   : definition
          #
          #   term2
          #   : first
          #   : second
          #
          # Only applies when no item has a nested DefinitionList —
          # the flat syntax has no nesting mechanism.
          class Flat < Base
            class << self
              def applies?(list, _ctx)
                list.items.none? { |term| term.nested }
              end

              def render(list, _ctx)
                list.items.map do |term|
                  lines = [term.text.to_s]
                  term.definitions.each do |defn|
                    content_str = defn.content.to_s
                    content_str.lines.each_with_index do |line, i|
                      stripped = line.rstrip
                      next if i.positive? && stripped.empty?

                      lines << ": #{stripped}"
                    end
                  end
                  lines.join("\n")
                end.join("\n\n")
              end
            end
          end
        end
      end
    end
  end
end
