# frozen_string_literal: true

require 'coradoc/core_model'

module Coradoc
  module Html
    module Transform
      # Transforms HTML input models to CoreModel equivalents
      #
      # HTML input converters now produce CoreModel directly, so this transformer
      # is largely a pass-through that ensures the model is CoreModel.
      class ToCoreModel
        class << self
          # Transform an HTML input model to CoreModel
          #
          # @param model [Object] HTML input model to transform
          # @return [Coradoc::CoreModel::Base] CoreModel equivalent
          def transform(model)
            # HTML input now produces CoreModel directly
            transform_direct(model)
          end

          private

          def transform_direct(model)
            case model
            when Coradoc::CoreModel::Base
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
