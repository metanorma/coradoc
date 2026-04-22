# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module List
          class Ordered < Core
            private

            def prefix
              return @model.marker if @model.marker

              '.' * [@model.ol_count, 1].max
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::List::Ordered, List::Ordered)
      end
    end
  end
end
