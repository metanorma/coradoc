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

              def render(list, ctx)
                list.items.map do |term|
                  render_term(term, ctx)
                end.join("\n\n")
              end

              def render_term(term, ctx)
                term_text = term.children.any? ? ctx.serialize_inline_join(term.children) : term.text.to_s
                lines = [term_text]
                term.definitions.each do |defn|
                  append_definition_lines(lines, defn, ctx)
                end
                lines.join("\n")
              end

              def append_definition_lines(lines, defn, ctx)
                content_str = defn.children.any? ? ctx.serialize_inline_join(defn.children) : defn.content.to_s
                content_str.lines.each_with_index do |line, i|
                  stripped = line.rstrip
                  next if i.positive? && stripped.empty?

                  lines << ": #{stripped}"
                end
              end
            end
          end
        end
      end
    end
  end
end
