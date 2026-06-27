# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Audio < MediaBase
        INSTANCE = new

        private

        def semantic_type
          :audio
        end
      end

      register :audio, Audio::INSTANCE
    end
  end
end
