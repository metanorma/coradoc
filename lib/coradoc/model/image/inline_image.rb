# frozen_string_literal: true

module Coradoc
  module Model
    module Image
      class InlineImage < Coradoc::Model::Image::Core
        attribute :colons, :string, default: -> { ":" }
      end
    end
  end
end
