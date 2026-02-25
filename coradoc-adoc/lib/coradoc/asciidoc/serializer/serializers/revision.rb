# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Revision < Base
          def to_adoc(model, _options = {})
            if model.date.nil? && model.remark.nil?
              "v#{model.number}\n"
            elsif model.remark.nil?
              "#{model.number}, #{model.date}\n"
            elsif model.date.nil?
              "#{model.number}: #{model.remark}\n"
            else
              "#{model.number}, #{model.date}: #{model.remark}\n"
            end
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Revision, Serializers::Revision)
    end
  end
end
