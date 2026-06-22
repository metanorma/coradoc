# frozen_string_literal: true

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Admonition
          # Each strategy renders an admonition (type, content, optional
          # title) for a specific output form. The active strategy is
          # chosen by `config.admonition_style`.
          #
          # Strategies are stateless; all state flows through arguments.
          # Adding a new admonition form = adding one file + one entry
          # in Registry::MODES.
          class Base
            class << self
              def render(_admonition, _ctx)
                raise NotImplementedError
              end

              def mode_name
                name.split('::').last.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
              end

              # Render the admonition body, preferring typed children
              # (so cross-refs, code spans, etc. survive) and falling
              # back to the plain-text content attribute when there are
              # no children or the ctx can't serialize them.
              def render_body(admonition, ctx)
                children = admonition.children
                return admonition.content.to_s if children.nil? || children.empty?

                ctx.serialize_inline_join(children)
              end
            end
          end
        end
      end
    end
  end
end
