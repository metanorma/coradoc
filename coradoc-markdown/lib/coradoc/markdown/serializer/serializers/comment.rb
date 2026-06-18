# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        # Comments are editorial annotations, not document content. The
        # Markdown Serialization Spec (§Comments) requires that comments
        # be suppressed by default.
        #
        # Behavior:
        #   suppress_comments == true  → '' (no output)
        #   suppress_comments == false → '<!-- text -->'
        class Comment < ElementSerializer
          handles_type ::Coradoc::Markdown::Comment

          def call(element, ctx)
            return '' if ctx.config.suppress_comments

            text = element.text.to_s.strip
            return '<!---->' if text.empty?

            "<!-- #{text} -->"
          end
        end
      end
    end
  end
end
