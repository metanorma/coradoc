# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class Side < Core
            def to_adoc(model, _options = {})
              @model = model
              "\n\n#{gen_anchor}#{gen_title}#{gen_attributes}#{gen_delimiter}\n\n\n" <<
                gen_lines << "\n\n#{gen_delimiter}\n\n"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Block::Side, Block::Side)
      end
    end
  end
end
