# frozen_string_literal: true

require_relative "block_image/attribute_list"

module Coradoc
  module Model
    module Image
      class BlockImage < Coradoc::Model::Image::Core
        attribute :colons, :string, default: -> { "::" }
        attribute :attributes,
                  Coradoc::Model::Image::BlockImage::AttributeList,
                  default: -> {
                    Coradoc::Model::Image::BlockImage::AttributeList.new
                  }
      end
    end
  end
end
