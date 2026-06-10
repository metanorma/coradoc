# frozen_string_literal: true

require 'nokogiri'
require 'coradoc/core_model'

module Coradoc
  module Html
    module Transform
      # Transforms Nokogiri HTML nodes to CoreModel
      #
      # Nokogiri serves as the HTML model layer. This transformer converts
      # Nokogiri::XML::Document or Nokogiri::XML::Node objects into CoreModel
      # by delegating to the existing input converter pipeline.
      class ToCoreModel
        include Coradoc::Transform::Base

        class << self
          # Transform an HTML model (Nokogiri node) to CoreModel
          #
          # @param model [Nokogiri::XML::Document, Nokogiri::XML::Node, Coradoc::CoreModel::Base]
          #   HTML input model to transform
          # @return [Coradoc::CoreModel::Base] CoreModel equivalent
          def transform(model)
            case model
            when Coradoc::CoreModel::Base
              model
            when Nokogiri::XML::Document, Nokogiri::XML::Node
              ::Coradoc::Input::Html::HtmlConverter.to_core_model(model)
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
