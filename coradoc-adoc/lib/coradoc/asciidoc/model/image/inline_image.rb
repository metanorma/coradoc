# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Image
        class InlineImage < Coradoc::AsciiDoc::Model::Image::Core
          attribute :colons, :string, default: -> { ':' }
        end
      end
    end
  end
end
