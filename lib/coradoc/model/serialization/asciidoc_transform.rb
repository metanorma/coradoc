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
          puts
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
          handle_substructure(data)
          # # TODO:
          # puts data

          # mappings = context.mappings_for(:asciidoc).mappings
          # puts "got model_class: #{model_class}"
          # instance = model_class.new
          # # puts "\033[1minstance\033[m is: #{instance.inspect}"

          # defaults_used = []

          # # mappings.each do |rule|
          # #   pp rule
          # # end

          # # Get parsed_element mapping
          # parsed_element_class = mappings.find { |m|
          #   m.field_type == :parsed_element
          # }
          #   &.to

          # return unless parsed_element_class
          # return unless data.is_a?(parsed_element_class)

          # mappings.reject(&:model_map?).each do |rule|
          #   raise "Attribute '#{rule.to}' not found in #{context}" unless valid_rule?(rule)

          #   attr = attribute_for_rule(rule)
          #   next if attr&.derived?

          #   # puts "\033[1mattr\033[m: #{attr.inspect}"

          #   # puts "attr: #{attr.inspect}"
          #   # value = false
          #   puts " `- attribute is: \033[1m#{rule.to}\033[m -> #{attr.inspect}"
          #   # puts
          #   # puts "`- \033[1mrule\033[m             is: #{rule.inspect}"
          #   # puts "`- \033[1mrule.field_type\033[m  is: #{rule.field_type.inspect}"
          #   # puts "`- \033[1mrule.name\033[m        is: #{rule.name.inspect}"
          #   # puts "`- \033[1mrule.to\033[m          is: #{rule.to.inspect}"
          #   # puts
          #   # puts "data[0] is"
          #   # pp data[0]
          #   # puts
          #   # puts
          #   # puts
          #   # # value = data[0]
          #   value = begin
          #     val = handle_substructure(data[0], attr)

          #     if (Lutaml::Model::Utils.uninitialized?(val) || val.nil?) && (instance.using_default?(rule.to) || rule.render_default)
          #       defaults_used << rule.to
          #       attr&.default(register) || rule.to_value_for(instance)
          #     else
          #       val
          #     end
          #   end

          #   value = apply_value_map(
          #     value,
          #     rule.value_map(:from, options),
          #     attr,
          #   )
          #   if value
          #     instance.public_send(:"#{rule.to}=", value)
          #   end

          #   # rule.deserialize(instance, value, attributes, context)
          # end

          # defaults_used.each do |attr_name|
          #   instance.using_default_for(attr_name)
          # end

          # instance
        end

        def model_to_data(model, _options = {})
          # TODO:
          puts model
        end

        protected

        # Getting recursive...
        def handle_substructure(data, attribute: nil)
          puts
          puts "         data is: #{data.inspect}"
          puts "         attribute is: #{attribute.inspect}"

          if attribute.nil?
            puts "        attribute is nil"
            puts "        maybe get this from context?"
            mappings = context.mappings_for(:asciidoc).mappings
            puts "got model_class: #{model_class}"
            instance = model_class.new
            # puts "\033[1minstance\033[m is: #{instance.inspect}"
            attributes = model_class.attributes
          else
            # wait: get mapping to map from element
            puts "    attribute not nil.  Handling substructure for attribute: #{attribute.type.inspect}"

            if data.is_a?(attribute.type)
              puts "data is a #{attribute.type} instance"
            end

            attribute_class = attribute.type

            # Get the correct class for the attribute, if it's polymorphic
            if attribute.options[:polymorphic]
              puts
              puts " *** attribute is polymorphic *** "
              puts
              attribute_class = attribute.options[:polymorphic].find { |klass|
                # puts "checking if #{klass} matches #{data.class}"
                klass.respond_to?(:mappings_for) &&
                  klass.mappings_for(:asciidoc)&.mappings&.any? do |rule|
                    # puts "checking rule #{rule.inspect} for #{klass}"
                    rule.field_type == :parsed_element && data.is_a?(rule.to)
                  end
              }
            else
              puts "attribute_class is not polymorphic: #{attribute_class.inspect}"
              puts "mapping is:"
              # puts attribute_class.mappings_for(:asciidoc).mappings.inspect
            end

            if attribute_class < Lutaml::Model::Type::Value
              puts "attribute_class is a Lutaml::Model::Type::Value :  #{data.inspect}"
              # TODO: handle mappings, instance, attributes?
              # puts "returning data.value: #{data.value.inspect}"
              puts "attribute_class: #{attribute_class.inspect}"
              # TODO: handle polymorphic :string and TextElement
              # TODO: If attribute_class is a Lutaml::Model::Type::String, and data is type Coradoc::Element::TextElement,
              # cast it to Coradoc::Model::TextElement
              return data.content
            else
              puts "attribute_class is: #{attribute_class.inspect}"
              mappings = attribute_class.mappings_for(:asciidoc).mappings
              instance = attribute_class.new
              attributes = attribute_class.attributes
            end

          end

          parsed_element_class = mappings&.find { |m|
            m.field_type == :parsed_element
          }
            &.to

          puts "parsed_element_class is: #{parsed_element_class&.inspect}"
          puts "what is data.class: #{data.class}"
          puts "what is data: #{data.inspect}"

          # Return early if no parsed_element_class is found or if data is not an instance of it
          return unless parsed_element_class
          return unless data.is_a?(parsed_element_class)

          # Book keeping
          # XXX: Why is it not seen being used in transforms other than
          # official Lutaml XML Transform?
          # I suppose it's because it's only used to determine whether to
          # render default values, when paired with 'render_default?',
          # in Lutaml MappingRule.
          defaults_used = []

          # Loop over all its attributes
          #
          mappings.reject(&:model_map?).each do |rule|
            puts "what is rule: name:#{rule.name}, to:#{rule.to}, field_type:#{rule.field_type}"

            attr = attributes[rule.to]
            next if attr&.derived?

            attr_value = data.public_send(rule.to)
            puts "    \033[1mattr\033[m: #{attr.inspect}"
            puts "    attribute is : \033[1m#{rule.to}\033[m -> #{attr_value.class}"

            # value = case attr_value
            #         when Array # TODO: or any other iterables?
            #           puts "    attr_value is an Array"
            #           attr_value.map { |v|
            #             case v
            #             when Lutaml::Model::Type::Value
            #               puts "    v is a Lutaml::Model::Type::Value"
            #               v.value
            #             # when Lutaml::Model::Serialize
            #             #   handle_substructure(v, attribute: attr)
            #             when Coradoc::Element::Base
            #               puts "    TODO: v is a something else, handle with care: #{v.inspect}"
            #               handle_substructure(v, attribute: attr)
            #             end
            #           }
            #         else
            #           puts "    attr_value is not an Array"
            #           puts "    attr_value is: #{attr_value.inspect}"
            #           val = handle_substructure(attr_value, attribute: attr)
            #           if (Lutaml::Model::Utils.uninitialized?(val) || val.nil?) && (instance.using_default?(rule.to) || rule.render_default)
            #             # Book keeping
            #             defaults_used << rule.to
            #             attr&.default(register) || rule.to_value_for(instance)
            #           else
            #             val
            #           end
            #         end
            value = if attr.collection?
                      puts "    attr_value is a collection. Entering map:"
                      attr_value.map { |v|
                        case v
                        when Lutaml::Model::Type::Value
                          puts "    v is a Lutaml::Model::Type::Value"
                          v.value
                        # when Lutaml::Model::Serialize
                        #   handle_substructure(v, attribute: attr)
                        when Coradoc::Element::Base
                          puts "        TODO: v is a something else, handle with care: #{v.inspect}"
                          handle_substructure(v, attribute: attr)
                        end
                      }
                    else
                      puts "    attr_value is not an Array"
                      puts "    attr_value : #{attr}"
                      puts "    attr_value is: #{attr_value.inspect}"
                      val = case attr_value
                            when Lutaml::Model::Serializable, Lutaml::Model::Type::Value
                              handle_substructure(attr_value, attribute: attr)
                            else
                              attr_value
                            end
                      if (Lutaml::Model::Utils.uninitialized?(val) || val.nil?) && (instance.using_default?(rule.to) || rule.render_default)
                        # Book keeping
                        defaults_used << rule.to
                        attr&.default(register) || rule.to_value_for(instance)
                      else
                        val
                      end
                    end

            if value
              instance.public_send(:"#{rule.to}=", value)
            end
          end

          # Book keeping
          defaults_used.each do |attr_name|
            instance.using_default_for(attr_name)
          end

          instance
        end

        def mappings
          @mappings ||= context.mappings_for(:asciidoc).mappings
        end
      end
    end
  end
end
