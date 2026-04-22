# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Image
        # Base class for image elements in AsciiDoc documents.
        #
        # Images can be block-level (standalone paragraphs) or inline (within text).
        # This base class provides common functionality for both types.
        #
        # @!attribute [r] id
        #   @return [String, nil] Optional identifier for the image
        #
        # @!attribute [r] title
        #   @return [String, nil] Optional image title/alt text
        #
        # @!attribute [r] src
        #   @return [String] The image source URL or path
        #
        # @!attribute [r] attributes
        #   @return [Coradoc::AsciiDoc::Model::Image::Core::AttributeList] Image-specific attributes
        #
        # @!attribute [r] annotate_missing
        #   @return [String, nil] Annotation text for missing images
        #
        # @!attribute [r] line_break
        #   @return [String] Line break character (default: "")
        #
        # @!attribute [r] colons
        #   @return [String, nil] Colon positioning for attributes
        #
        # @see Coradoc::AsciiDoc::Model::Image::BlockImage Block-level images
        # @see Coradoc::AsciiDoc::Model::Image::InlineImage Inline images
        #
        class Core < Coradoc::AsciiDoc::Model::Base
          # Autoload nested AttributeList class
          autoload :AttributeList, 'coradoc/asciidoc/model/image/core/attribute_list'

          include Coradoc::AsciiDoc::Model::Anchorable

          attribute :id, :string
          attribute :title, :string
          attribute :src, :string
          attribute :attributes,
                    Coradoc::AsciiDoc::Model::Image::Core::AttributeList,
                    default: lambda {
                      ::Coradoc::AsciiDoc::Model::AttributeList.new
                    }
          attribute :annotate_missing, :string
          attribute :line_break, :string, default: -> { '' }
          attribute :colons, :string

          # Aliases for common attribute accessors
          alias path src
          alias alt title

          # Custom to_adoc implementation that uses ElementRegistry directly
          # to avoid recursion issues with image serialization.
          #
          # @return [String] AsciiDoc representation of this image
          def to_adoc
            # Use the registered serializer rather than Coradoc::AsciiDoc::Serializer.serialize
            # to avoid recursion
            serializer_class = Coradoc::AsciiDoc::Serializer::ElementRegistry.lookup(self.class)
            serializer_class.new.to_adoc(self)
          end
        end
      end
    end
  end
end
