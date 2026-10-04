# frozen_string_literal: true

require 'leptris'
require 'coradoc'

module Coradoc
  module Html
    module Transform
      # Transforms Leptris HTML nodes to CoreModel
      #
      # Leptris serves as the HTML model layer. This transformer converts
      # Leptris::XML::Document or Leptris::XML::Node objects into CoreModel
      # by delegating to the existing input converter pipeline.
      class ToCoreModel
        class << self
          # Transform an HTML model (Leptris node) to CoreModel
          #
          # @param model [Leptris::XML::Document, Leptris::XML::Node, Coradoc::CoreModel::Base]
          #   HTML input model to transform
          # @return [Coradoc::CoreModel::Base] CoreModel equivalent
          def transform(model)
            case model
            when Coradoc::CoreModel::Base
              model
            when Leptris::XML::Document, Leptris::XML::Node
              ::Coradoc::Html::HtmlConverter.to_core_model(model)
            when Array
              model.map { |item| transform(item) }
            else
              model
            end
          end
        end

        def transform(model) = self.class.transform(model)
      end
    end
  end
end
