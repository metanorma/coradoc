# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class CommentBlock < Base
          def to_adoc(model, _options = {})
            <<~ADOC.chomp
              ////
              #{model.text}
              ////#{model.line_break}
            ADOC
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::CommentBlock, Serializers::CommentBlock)
    end
  end
end
