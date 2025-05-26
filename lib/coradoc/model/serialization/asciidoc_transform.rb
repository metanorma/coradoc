# frozen_string_literal: true

module Coradoc
  module Model
    module Serialization
      class AsciidocTransform < Lutaml::Model::Transform
        # @param [Context] context The context object that provides attribute and mapping management
        # @param [Coradoc::Element::Base] data The Coradoc::Element::Base representation
        # @param [Symbol] format The format type (e.g., :asciidoc)
        # @param [Hash] options Additional options for transformation
        # @return [Lutaml::Model::Serialize] The transformed model instance
        def self.data_to_model(context, data, format, options = {})
          puts "data to model format: #{format.inspect}"
          puts "data to model data: #{data.inspect}"
          puts "data to model context: #{context.inspect}"
          new(context).data_to_model(data, options)
        end

        # @param [Context] context The context object that provides attribute and mapping management
        # @param [Lutaml::Model::Serialize] model The model to transform
        # @param [Symbol] format The format type (e.g., :asciidoc)
        # @param [Hash] options Additional options for transformation
        # @return [Coradoc::Element::Base] The transformed data
        def self.model_to_data(context, model, format, options = {})
          puts "model to data format: #{format}"
          new(context).model_to_data(model, options)
        end

        def data_to_model(data, _options = {})
          # TODO:
          puts data
        end

        def model_to_data(model, _options = {})
          # TODO:
          puts model
        end

        protected

        def mappings
          @mappings ||= context.mappings_for(:asciidoc).mappings
        end
      end
    end
  end
end
