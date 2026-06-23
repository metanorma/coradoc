# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        # Sidebar block — a callout box. VitePress maps the `:::info`
        # custom container to a styled callout, which matches AsciiDoc's
        # sidebar semantics without leaking raw HTML into the Markdown.
        class Sidebar < ElementSerializer
          handles_type ::Coradoc::Markdown::Sidebar

          def call(element, ctx)
            title = element.title.to_s
            header = title.empty? ? '' : " #{title}"
            body = render_body(element, ctx)
            ":::info#{header}\n#{body}\n:::"
          end

          private

          def render_body(element, ctx)
            return element.content.to_s.chomp if element.children.nil? || element.children.empty?

            element.children.map { |c| ctx.serialize(c) }.join("\n\n").chomp
          end
        end
      end
    end
  end
end
