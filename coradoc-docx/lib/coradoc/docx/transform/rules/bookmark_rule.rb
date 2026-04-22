# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms w:bookmarkStart to a metadata hash for attaching to
        # the next CoreModel element.
        #
        # Bookmarks in OOXML are position markers (not content containers).
        # The orchestrator collects bookmark IDs and attaches them as
        # element attributes on the containing paragraph/section.
        class BookmarkRule < Rule
          def matches?(element)
            return false unless defined?(Uniword::Wordprocessingml)

            element.is_a?(Uniword::Wordprocessingml::BookmarkStart) ||
              element.is_a?(Uniword::Wordprocessingml::BookmarkEnd)
          end

          # Returns a hash with bookmark metadata, not a CoreModel node.
          # The orchestrator uses this to set the id on the parent element.
          def apply(element, _context)
            if element.is_a?(Uniword::Wordprocessingml::BookmarkStart)
              { id: element.id&.to_s, name: element.name&.to_s }
            else
              nil # BookmarkEnd — no useful data
            end
          end
        end
      end
    end
  end
end
