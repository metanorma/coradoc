# frozen_string_literal: true

require_relative 'base'
require_relative 'flat'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module DefinitionList
          # HTML fallback for nested definition lists (Markdown syntax
          # cannot express nesting). Renders `<dl>` with recursive
          # `<dl>` inside `<dd>` for nested entries.
          #
          # For flat lists (no nesting), delegates to Flat to keep the
          # output Markdown-native and editable.
          class NestedHtml < Base
            class << self
              def applies?(list, _ctx)
                list.items.any? { |term| term.nested }
              end

              def render(list, ctx)
                # When the caller asked to flatten, never emit HTML.
                return Flat.render(list, ctx) if ctx.config.definition_list_nested == :flatten

                render_dl(list)
              end

              private

              def render_dl(list)
                items_html = list.items.map { |term| render_term(term) }.join
                "<dl>\n#{items_html}</dl>"
              end

              def render_term(term)
                dt = "<dt>#{term.text.to_s}</dt>"
                dds = term.definitions.map { |d| render_dd(d) }.join
                nested = term.nested ? "\n  #{render_dl(term.nested)}" : ''
                "#{dt}\n#{dds}#{nested unless nested.empty?}"
              end

              def render_dd(definition)
                content_str = definition.content.to_s.strip
                "<dd>\n  #{content_str}\n</dd>"
              end
            end
          end
        end
      end
    end
  end
end
