# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Silently ignores w:proofErr (proofing error) elements.
        #
        # Proofing errors are spelling/grammar markers in OOXML that have
        # no semantic representation in CoreModel. This rule matches them
        # and returns nil, effectively stripping them from the output.
        class ProofErrorRule < Rule
          def matches?(element)
            defined?(Uniword::Wordprocessingml::ProofError) &&
              element.is_a?(Uniword::Wordprocessingml::ProofError)
          end

          def apply(_element, _context)
            nil
          end
        end
      end
    end
  end
end
