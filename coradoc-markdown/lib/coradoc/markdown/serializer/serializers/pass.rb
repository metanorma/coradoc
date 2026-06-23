# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        # Pass block. AsciiDoc pass content is raw and bypasses all
        # substitutions. Markdown has no equivalent — kramdown's
        # `{::nomarkdown}` extension is not supported by VitePress /
        # markdown-it, so emitting it leaks raw HTML that breaks Vue's
        # template compiler.
        #
        # Emit as an HTML comment so the content is preserved (for
        # debugging or downstream tooling) but never rendered as HTML.
        class Pass < ElementSerializer
          handles_type ::Coradoc::Markdown::Pass

          def call(element, _ctx)
            content = element.content.to_s
            stripped = content.gsub(/\A\n+|\n+\z/, '')
            comment_body = stripped.empty? ? '' : " #{stripped} "
            "<!--#{comment_body}-->"
          end
        end
      end
    end
  end
end
