# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module List
          class Definition < Base
            def to_adoc(model, _options = {})
              @model = model
              content = +"\n"
              @model.items.each do |item|
                # Pass delimiter to item serialization
                serialized = serialize_child_with_options(item, delimiter: @model.delimiter)
                content << serialized
              end
              content
            end

            private

            def serialize_child_with_options(child, options = {})
              serializer_class = ElementRegistry.lookup(child.class)
              serializer = serializer_class.new
              serializer.to_adoc(child, options)
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::List::Definition, List::Definition)
      end
    end
  end
end
