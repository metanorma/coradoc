# frozen_string_literal: true

module Coradoc
  module Model
    module Serialization
      class AsciidocTransform < Lutaml::Model::Transform
        def self.data_to_model(context, data, _format, _options = {})
          new(context).data_to_model(data)
        end

        def self.model_to_data(context, model, _format, _options = {})
          new(context).model_to_data(model)
        end

        def data_to_model(data)
          mappings = context.mappings_for(:asciidoc)

          data.attributes.map do |_type, entry|
            asciidoc_entry = model_class.new

            mappings.mappings.map do |mapping|
              attribute = attributes[mapping.to]
              field_value = if mapping.entry_type?
                              entry.entry_type
                            elsif mapping.content?
                              entry.content
                            else
                              entry.attributes[mapping.name]
                            end

              if field_value
                asciidoc_entry.public_send(
                  :"#{mapping.to}=",
                  attribute.type.from_asciidoc(field_value),
                )
              end
            end

            asciidoc_entry
          end
        end

        NON_ATTRIBUTES_FIELD_TYPES = %i[content entry_type].freeze

        def model_to_data(model)
          entry_type = model.entry_type
          content = model.content
          mapping = context.mappings_for(:asciidoc)

          attributes = mapping.mappings.each_with_object({}) do |m, acc|
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

          { entry_type: AsciidocDocumentEntry.new(
            entry_type: entry_type,
            content: content,
            attributes: attributes,
          ) }
        end
      end
    end
  end
end
