# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class ReviewerNote < Base
          def to_adoc(model, _options = {})
            attrs = []
            attrs << "reviewer=#{model.reviewer}" if model.reviewer
            attrs << "date=#{model.date}" if model.date
            attrs << "from=#{model.from}" if model.from
            attrs << "to=#{model.to}" if model.to

            result = "[#{attrs.join(',')}]\n"
            result += "****\n"
            result += serialize_children(model.content) if model.content
            result += "****\n"
            result
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::ReviewerNote, Serializers::ReviewerNote)
    end
  end
end
