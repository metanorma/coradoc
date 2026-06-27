# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      # Registry for mapping Coradoc model classes to their AsciiDoc serializers.
      #
      # Thin layer over `Coradoc::Dispatch.strict`: each public method
      # delegates to a single Dispatch instance so the dispatch mechanism
      # (storage, miss-handling, override semantics) lives in one place.
      # Adoc-specific concerns (the ArgumentError wording on miss, the
      # `registered_models` name) stay here.
      #
      # @example Registering a custom serializer
      #   ElementRegistry.override(Model::Paragraph, CustomParagraphSerializer)
      #
      # @example Wrapping an existing serializer
      #   original = ElementRegistry.get(Model::Paragraph)
      #   ElementRegistry.override(Model::Paragraph, WrapperSerializer.new(original))
      class ElementRegistry
        DISPATCH = Coradoc::Dispatch.strict

        class << self
          def register(model_class, serializer_class)
            DISPATCH.register(model_class, serializer_class)
          end

          def override(model_class, serializer_class)
            DISPATCH.override(model_class, serializer_class)
          end

          def unregister(model_class)
            DISPATCH.unregister(model_class)
          end

          def get(model_class)
            DISPATCH.lookup(model_class)
          end

          def lookup(model_class)
            serializer_class = DISPATCH.lookup(model_class)
            return serializer_class if serializer_class

            raise ArgumentError,
                  "No serializer registered for #{model_class.name}. " \
                  'Please register a serializer in ElementRegistry, or the serializer ' \
                  'may not have been loaded yet (check Registrations.load_all!)'
          end

          def registered_models
            DISPATCH.registered_keys
          end

          def registered?(model_class)
            DISPATCH.registered?(model_class)
          end

          def clear!
            DISPATCH.clear!
          end
        end
      end
    end
  end
end
