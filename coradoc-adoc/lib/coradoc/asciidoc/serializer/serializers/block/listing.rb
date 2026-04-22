# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class Listing < Core
            def to_adoc(model, _options = {})
              @model = model
              "\n\n#{gen_anchor}#{gen_attributes}\n#{gen_delimiter}\n" <<
                gen_lines << "\n#{gen_delimiter}\n\n"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Block::Listing, Block::Listing)
      end
    end
  end
end
