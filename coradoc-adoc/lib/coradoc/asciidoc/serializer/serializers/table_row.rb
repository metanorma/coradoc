# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class TableRow < Base
          def to_adoc(model, _options = {})
            @model = model
            delim = @model.asciidoc? ? "\n" : ' '
            result = "#{@model.columns.map(&:to_adoc).join(delim)}\n"

            # Add extra newline for header or asciidoc rows
            result += "\n" if @model.header || @model.asciidoc?
            result
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::TableRow, Serializers::TableRow)
    end
  end
end
