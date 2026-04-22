# frozen_string_literal: true

module Coradoc
  module Html
    module Transform
      # Transforms CoreModel models to HTML output
      #
      # This transformer converts CoreModel to structures suitable for
      # HTML rendering. Note: The HTML converters already support CoreModel
      # directly, so this transformer primarily passes through the CoreModel.
      class FromCoreModel
        class << self
          # Transform a CoreModel to HTML-ready structure
          #
          # @param model [Coradoc::CoreModel::Base] CoreModel to transform
          # @return [Object] HTML-ready structure
          def transform(model)
            case model
            when Coradoc::CoreModel::Base
              # HTML converters already support CoreModel directly
              model
            when Array
              model.map { |item| transform(item) }
            else
              model
            end
          end
        end
      end
    end
  end
end
