# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Html
    module Converters
      # Converter for SourceCode blocks
      #
      # SourceCode models use the `lines` attribute, while Source models use `content`.
      class SourceCode < Source
        # The parent Source class already handles both content and lines attributes
        # after our recent update, so we just need to inherit.
      end
    end
  end
end
