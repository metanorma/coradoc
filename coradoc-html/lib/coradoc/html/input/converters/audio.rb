# frozen_string_literal: true

require_relative 'media_base'

module Coradoc
  module Input
    module Html
      module Converters
        class Audio < MediaBase
          private

          def semantic_type
            :audio
          end
        end

        register :audio, Audio.new
      end
    end
  end
end
