# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms w:sdt (Structured Document Tag) elements.
        #
        # SDTs wrap content with additional metadata. The transform
        # unwraps them and delegates to the content's own rules.
        class StructuredDocumentTagRule < Rule
          def matches?(element)
            defined?(Uniword::Wordprocessingml::StructuredDocumentTag) &&
              element.is_a?(Uniword::Wordprocessingml::StructuredDocumentTag)
          end

          def apply(sdt, context)
            # SDTs contain paragraphs and tables — delegate to their rules
            # via the context's transform method
            return nil unless sdt.content

            paragraphs = sdt.content.paragraphs || []
            tables = sdt.content.tables || []

            results = []
            paragraphs.each { |p| results << context.transform(p) }
            tables.each { |t| results << context.transform(t) }

            # Return single element or array
            results.one? ? results.first : results.compact
          end
        end
      end
    end
  end
end
