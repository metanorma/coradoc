# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Image
        class BlockImage < Coradoc::AsciiDoc::Model::Image::Core
          # Autoload nested AttributeList class
          autoload :AttributeList, 'coradoc/asciidoc/model/image/block_image/attribute_list'

          attribute :colons, :string, default: -> { '::' }
          attribute :attributes,
                    Coradoc::AsciiDoc::Model::Image::BlockImage::AttributeList,
                    default: lambda {
                      ::Coradoc::AsciiDoc::Model::AttributeList.new
                    }
        end
      end
    end
  end
end
