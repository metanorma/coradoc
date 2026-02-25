# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms w:footnoteReference to CoreModel::FootnoteReference.
        #
        # Footnote content is looked up from the context's footnotes map,
        # which is populated by the ToCoreModel orchestrator before
        # transforming body elements.
        class FootnoteRule < Rule
          def matches?(element)
            defined?(Uniword::Wordprocessingml::FootnoteReference) &&
              element.is_a?(Uniword::Wordprocessingml::FootnoteReference)
          end

          def apply(ref, _context)
            id = ref.id&.to_s

            CoreModel::FootnoteReference.new(id: id)
          end
        end
      end
    end
  end
end
