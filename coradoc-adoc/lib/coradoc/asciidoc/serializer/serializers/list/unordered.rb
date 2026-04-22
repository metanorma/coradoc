# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module List
          class Unordered < Core
            private

            def prefix
              # Use the marker from the first list item if available
              return @model.items.first.marker if @model.items.first&.marker

              # Otherwise use the list-level marker if set
              return @model.marker if @model.marker

              # Default to asterisk markers
              '*' * [@model.ol_count, 1].max
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::List::Unordered, List::Unordered)
      end
    end
  end
end
