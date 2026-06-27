# frozen_string_literal: true

require 'coradoc'

module Coradoc
  module Html
    module Transform
      # Transforms CoreModel to HTML output
      #
      # This transformer converts CoreModel to HTML strings by delegating
      # to the existing theme/renderer pipeline.
      class FromCoreModel
        class << self
          # Transform a CoreModel to HTML string
          #
          # @param model [Coradoc::CoreModel::Base, Array] CoreModel to transform
          # @param options [Hash] Renderer options (e.g., theme)
          # @return [String] HTML output
          def transform(model, options = {})
            case model
            when Coradoc::CoreModel::Base
              Html.serialize(model, options)
            when Array
              model.map { |item| transform(item, options) }.join("\n")
            else
              model.to_s
            end
          end
        end

        def transform(model, options = {}) = self.class.transform(model, options)
      end
    end
  end
end
