# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Bibliography < Base
          def to_adoc(model, _options = {})
            @model = model
            adoc = "#{gen_anchor}\n"
            adoc << '[bibliography]'
            adoc << "== #{model.title}\n\n"
            model.entries&.each do |entry|
              adoc << "#{entry.to_adoc}\n"
            end
            adoc
          end

          private

          attr_reader :model

          def gen_anchor
            return '' unless @model.anchor

            @model.anchor.to_adoc
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Bibliography, Serializers::Bibliography)
    end
  end
end
