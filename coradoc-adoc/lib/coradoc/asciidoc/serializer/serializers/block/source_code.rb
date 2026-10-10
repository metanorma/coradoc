# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class SourceCode < Core
            def to_adoc(model, _options = {})
              @model = model
              lang = model.lang.to_s.strip
              header = lang.empty? ? '[source]' : "[source,#{lang}]"
              "\n\n#{gen_anchor}#{header}\n#{gen_delimiter}\n" <<
                gen_lines << "\n#{gen_delimiter}\n\n"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Block::SourceCode, Block::SourceCode)
      end
    end
  end
end
