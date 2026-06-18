# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        # Pass block: emit content inside kramdown's nomarkdown extension
        # so it bypasses Markdown rendering.
        class Pass < ElementSerializer
          handles_type ::Coradoc::Markdown::Pass

          def call(element, _ctx)
            "{::nomarkdown}#{element.content.to_s}{:/}"
          end
        end
      end
    end
  end
end
