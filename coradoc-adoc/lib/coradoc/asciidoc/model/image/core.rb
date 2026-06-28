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
        # Typed promotion of attribute-list slots
        # ---------------------------------------
        #
        # Semantically meaningful image attributes (`alt`, `role`, `width`,
        # `height`, `link`) are declared as typed lutaml-model fields on
        # `Core` itself — not as validators on a generic bag. The class-level
        # {promoted_positional} and {promoted_named} methods are the single
        # source of truth for which slots get lifted into typed fields and in
        # what order; subclasses override them to reflect syntax differences
        # (e.g. inline images treat the 2nd positional as `role`, block images
        # do not).
        #
        # The lift itself is performed by {AttributeExtractor}, a pure function
        # over (AttributeList, target_class) → (extracted_hash, residual_list).
        # Anything not promoted stays in `attributes` for round-trip fidelity.
        class Core < Coradoc::AsciiDoc::Model::Base
          # Autoload nested AttributeList class
          autoload :AttributeList, 'coradoc/asciidoc/model/image/core/attribute_list'

          include Coradoc::AsciiDoc::Model::Anchorable

          attribute :id, :string
          attribute :title, :string
          attribute :src, :string
          attribute :alt, :string
          attribute :caption, :string
          attribute :role, :string
          attribute :width, :string
          attribute :height, :string
          attribute :link, :string
          attribute :attributes,
                    Coradoc::AsciiDoc::Model::Image::Core::AttributeList,
                    default: lambda {
                      ::Coradoc::AsciiDoc::Model::AttributeList.new
                    }
          attribute :annotate_missing, :string
          attribute :line_break, :string, default: -> { '' }
          attribute :colons, :string

          alias path src

          # Positional attribute-list slots that this image class promotes to
          # typed fields, in order. Subclasses override to reflect their
          # syntax. Index 0 → alt for all image kinds; index 1 → role for
          # inline images only.
          # @return [Array<Symbol>]
          def self.promoted_positional
            %i[alt]
          end

          # Named attribute-list keys that this image class promotes to typed
          # fields. The same set applies to both inline and block images.
          # @return [Array<Symbol>]
          def self.promoted_named
            %i[width height link role]
          end

          # Custom to_adoc implementation that uses ElementRegistry directly
          # to avoid recursion issues with image serialization.
          #
          # @return [String] AsciiDoc representation of this image
          def to_adoc
            serializer_class = Coradoc::AsciiDoc::Serializer::ElementRegistry.lookup(self.class)
            serializer_class.new.to_adoc(self)
          end
        end
      end
    end
  end
end
