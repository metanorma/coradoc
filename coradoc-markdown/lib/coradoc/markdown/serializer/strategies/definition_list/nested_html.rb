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

                render_dl(list, ctx)
              end

              private

              def render_dl(list, ctx)
                items_html = list.items.map { |term| render_term(term, ctx) }.join
                "<dl>\n#{items_html}</dl>"
              end

              def render_term(term, ctx)
                dt_text = if term.children.any?
                            ctx.serialize_inline_join(term.children)
                          else
                            term.text.to_s
                          end
                dt = "<dt>#{dt_text}</dt>"
                dds = term.definitions.map { |d| render_dd(d, ctx) }.join
                nested = term.nested ? "\n  #{render_dl(term.nested, ctx)}" : ''
                "#{dt}\n#{dds}#{nested unless nested.empty?}"
              end

              def render_dd(definition, ctx)
                content_str = if definition.children.any?
                                ctx.serialize_inline_join(definition.children).strip
                              else
                                definition.content.to_s.strip
                              end
                "<dd>\n  #{content_str}\n</dd>"
              end
            end
          end
        end
      end
    end
  end
end
