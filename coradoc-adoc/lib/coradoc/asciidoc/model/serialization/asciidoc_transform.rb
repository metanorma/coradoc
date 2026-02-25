# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Serialization
        # Transform class for converting between Coradoc::Element and Lutaml::Model objects
        #
        # This handles bidirectional transformation for AsciiDoc serialization:
        # - data_to_model: Coradoc::Element -> Lutaml::Model::Serializable
        # - model_to_data: Lutaml::Model::Serializable -> Coradoc::Element
        #
        class AsciidocTransform < Lutaml::Model::Transform
          # Convert Coradoc::Element data to Lutaml::Model instance
          #
          # @param context [Context] The context with attribute and mapping management
          # @param data [Coradoc::Element::Base] The Coradoc element to convert
          # @param format [Symbol] The format type (:asciidoc)
          # @param options [Hash] Additional options
          # @return [Lutaml::Model::Serializable] The model instance
          def self.data_to_model(context, data, _format, options = {})
            new(context).data_to_model(data, options)
          end

          # Convert Lutaml::Model instance to Coradoc::Element data
          #
          # @param context [Context] The context with attribute and mapping management
          # @param model [Lutaml::Model::Serializable] The model to convert
          # @param format [Symbol] The format type (:asciidoc)
          # @param options [Hash] Additional options
          # @return [Coradoc::Element::Base] The Coradoc element
          def self.model_to_data(context, model, _format, options = {})
            new(context).model_to_data(model, options)
          end

          # Transform Coradoc::Element to model instance
          def data_to_model(data, options = {})
            return nil if data.nil?

            # Get mappings for asciidoc format
            mappings = context.mappings_for(:asciidoc)
            return nil unless mappings

            mapping_rules = mappings.mappings
            return nil unless mapping_rules

            # Find the parsed_element mapping to get target class
            parsed_element_rule = mapping_rules.find { |m| m.field_type == :parsed_element }
            return nil unless parsed_element_rule

            target_class = parsed_element_rule.to
            return nil unless target_class

            # Validate data type if from is specified
            return nil if parsed_element_rule.from && !data.is_a?(parsed_element_rule.from)

            # Create instance and populate attributes
            instance = target_class.new
            attributes = target_class.attributes
            defaults_used = []

            mapping_rules.reject(&:model_map?).each do |rule|
              attr = attributes[rule.to]
              next if attr&.derived?

              # Get value from source data
              source_value = data.public_send(rule.name || rule.to)

              # Transform the value
              value = transform_value(source_value, attr, options)

              # Handle defaults
              if value.nil? && (instance.using_default?(rule.to) || rule.render_default)
                defaults_used << rule.to
                value = attr&.default || rule.to_value_for(instance)
              end

              # Apply value map if present
              value = apply_value_map(value, rule.value_map(:from, options), attr) if rule.respond_to?(:value_map)

              # Set the value
              instance.public_send(:"#{rule.to}=", value) if value
            end

            # Mark defaults as used
            defaults_used.each { |attr_name| instance.using_default_for(attr_name) }

            instance
          end

          # Transform model instance to Coradoc::Element
          def model_to_data(model, options = {})
            return nil if model.nil?

            # Get mappings for asciidoc format
            mappings = context.mappings_for(:asciidoc)
            return nil unless mappings

            mapping_rules = mappings.mappings
            return nil unless mapping_rules

            # Find the parsed_element mapping to get target class
            parsed_element_rule = mapping_rules.find { |m| m.field_type == :parsed_element }
            return nil unless parsed_element_rule

            target_class = parsed_element_rule.from
            return nil unless target_class

            # Create instance and populate attributes
            attributes = model.class.attributes
            instance = target_class.new

            mapping_rules.reject(&:model_map?).each do |rule|
              attr = attributes[rule.to]
              next if attr&.derived?

              # Get value from model
              model_value = model.public_send(rule.to)
              next if model_value.nil?

              # Transform the value back
              value = transform_value_to_data(model_value, attr, options)

              # Set on target instance
              target_attr = rule.name || rule.to
              instance.public_send(:"#{target_attr}=", value) if instance.respond_to?("#{target_attr}=")
            end

            instance
          end

          protected

          # Transform a value from data to model format
          def transform_value(value, attr, options = {})
            return nil if value.nil?

            case value
            when Array
              value.map { |v| transform_single_value(v, attr, options) }
            else
              transform_single_value(value, attr, options)
            end
          end

          # Transform a single value
          def transform_single_value(value, attr, options = {})
            case value
            when Lutaml::Model::Type::Value
              value.value
            when Lutaml::Model::Serializable
              # Recursively transform nested models
              self.class.data_to_model(context, value, :asciidoc, options)
            when Coradoc::Element::Base
              # Already a Coradoc element, may need conversion
              if attr&.type&.<(Lutaml::Model::Type::Value)
                value.respond_to?(:content) ? value.content : value.to_s
              else
                value
              end
            else
              value
            end
          end

          # Transform a value from model to data format
          def transform_value_to_data(value, attr, options = {})
            case value
            when Array
              value.map { |v| transform_single_value_to_data(v, attr, options) }
            else
              transform_single_value_to_data(value, attr, options)
            end
          end

          # Transform a single value to data format
          def transform_single_value_to_data(value, _attr, options = {})
            case value
            when Lutaml::Model::Serializable
              # Recursively transform back to Coradoc element
              self.class.model_to_data(context, value, :asciidoc, options)
            when Lutaml::Model::Type::Value
              value.value
            else
              value
            end
          end

          # Apply value map transformation if present
          def apply_value_map(value, value_map, _attr)
            return value unless value_map

            case value_map[:type]
            when :symbolize_keys
              value.transform_keys(&:to_sym) if value.is_a?(Hash)
            when :stringify_keys
              value.transform_keys(&:to_s) if value.is_a?(Hash)
            else
              value
            end
          end

          # Get mappings for asciidoc format
          def mappings
            @mappings ||= context.mappings_for(:asciidoc)&.mappings || []
          end
        end
      end
    end
  end
end
