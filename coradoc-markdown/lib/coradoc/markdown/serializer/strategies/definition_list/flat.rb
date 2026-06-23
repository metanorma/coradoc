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
                  lines = [render_term(term, ctx)]
                  term.definitions.each do |defn|
                    content_str = render_definition(defn, ctx)
                    content_str.lines.each_with_index do |line, i|
                      stripped = line.rstrip
                      next if i.positive? && stripped.empty?

                      lines << ": #{stripped}"
                    end
                  end
                  lines.join("\n")
                end.join("\n\n")
              end

              private

              def render_term(term, ctx)
                children = term.text_children
                return term.text.to_s if children.nil? || children.empty?

                ctx.serialize_inline_join(children)
              end

              def render_definition(defn, ctx)
                children = defn.inline_content
                return defn.content.to_s if children.nil? || children.empty?

                ctx.serialize_inline_join(children)
              end
            end
          end
        end
      end
    end
  end
end
