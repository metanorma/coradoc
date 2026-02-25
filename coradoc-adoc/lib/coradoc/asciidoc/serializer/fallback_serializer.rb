# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      # Fallback serializer for models that don't have explicit serializers.
      #
      # NOTE: This serializer does NOT call to_adoc on the model to avoid
      # infinite recursion (model.to_adoc → Serializer.serialize → FallbackSerializer → model.to_adoc).
      # Instead, it raises a clear error indicating the serializer is missing.
      class FallbackSerializer
        def serialize(model, _options = {})
          raise ArgumentError,
                "No serializer registered for #{model.class.name}. " \
                'Please register a serializer in ElementRegistry, or the serializer ' \
                'may not have been loaded yet (check Registrations.load_all!)'
        end
      end
    end
  end
end
