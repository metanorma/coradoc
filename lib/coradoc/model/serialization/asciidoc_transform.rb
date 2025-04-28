# frozen_string_literal: true

module Coradoc
  module Model
    module Serialization
      class AsciidocTransform < Lutaml::Model::Transform
        # @param [Coradoc::Model::Serialize] context The context object that
        # provides attribute and mapping management, ser-deserialization,
        # dynamic method definitions, model transformation, etc.
        # @param [Hash] data The data to transform
        # @return [Array] of Hash, that represents the model, e.g. `[{document: ...}]`
        def self.data_to_model(context, data, _format, _options = {})
          new(context).data_to_model(data)
        end

        # @param [Coradoc::Model::Serialize] context The context object that
        # provides attribute and mapping management, ser-deserialization,
        # dynamic method definitions, model transformation, etc.
        # @param [Array] model Array of Hash, that represents the model, e.g. `[{document: ...}]`
        # @return [Hash] The data to transform
        def self.model_to_data(context, model, _format, _options = {})
          new(context).model_to_data(model)
        end

        def data_to_model(data)
          mappings = context.mappings_for(:asciidoc)

          data.attributes.map do |_type, entry|
            puts 'entry'
            puts entry.inspect
            puts "model_class"
            pp model_class
            asciidoc_entry = model_class.new

            mappings.mappings.map do |mapping|
              attribute = attributes[mapping.to]
              field_value = if mapping.content?
                              entry.content
                            else
                              entry.attributes[mapping.name]
                            end

              if field_value
                puts 'pp attribute'
                pp attribute
                asciidoc_entry.public_send(
                  :"#{mapping.to}=",
                  attribute.type.from_asciidoc(field_value),
                )
              end
            end

            asciidoc_entry
          end
        end

        # TODO: verify
        NON_ATTRIBUTES_FIELD_TYPES = %i[content].freeze

        def model_to_data(model)
          content = model.content
          mapping = context.mappings_for(:asciidoc)

          fields = mapping.mappings.each_with_object({}) do |m, acc|
            next if NON_ATTRIBUTES_FIELD_TYPES.include?(m.field_type)

            attribute = attributes[m.to]

            acc[m.name] = if attribute.collection?
                            model.send(m.to).map(&:to_asciidoc)
                          elsif model.send(m.to).respond_to?(:to_asciidoc)
                            model.send(m.to).to_asciidoc
                          else
                            model.send(m.to)
                          end
          end

          AsciidocDocumentEntry.new(
            content: content,
            attributes: fields,
          )
        end
      end
    end
  end
end
