# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module List
        # Unordered (bulleted) list for AsciiDoc documents.
        #
        # Unordered lists use asterisk markers (*, **, ***) and are
        # typically used for non-sequential items where order doesn't matter.
        #
        # @example Create an unordered list
        #   list = Coradoc::AsciiDoc::Model::List::Unordered.new
        #   item = Coradoc::AsciiDoc::Model::ListItem.new
        #   item.content = [Coradoc::AsciiDoc::Model::TextElement.new("Bullet point")]
        #   list.items << item
        #
        # @see Coradoc::AsciiDoc::Model::List::Core Base list class
        # @see Coradoc::AsciiDoc::Model::List::Ordered Ordered (numbered) lists
        #
        class Unordered < Core
          # Generate the prefix marker for this list level
          #
          # @return [String] The prefix marker (e.g., "*", "**", "***")
          def prefix
            return marker if marker

            '*' * [ol_count, 1].max
          end
        end
      end
    end
  end
end
