# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Image
        # Autoload image types lazily
        autoload :Core, 'coradoc/asciidoc/model/image/core'
        autoload :InlineImage, 'coradoc/asciidoc/model/image/inline_image'
        autoload :BlockImage, 'coradoc/asciidoc/model/image/block_image'
      end
    end
  end
end
