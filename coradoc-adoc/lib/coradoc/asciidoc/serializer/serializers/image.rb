# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload image serializers
        module Image
          autoload :Core, 'coradoc/asciidoc/serializer/serializers/image/core'
        end
      end
    end
  end
end
