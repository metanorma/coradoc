# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class CommentLine < Base
          def to_adoc(model, _options = {})
            if model.text.nil? || model.text.strip.empty?
              "//#{model.line_break}"
            else
              "// #{model.text}#{model.line_break}"
            end
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::CommentLine, Serializers::CommentLine)
    end
  end
end
