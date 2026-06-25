# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        # Transforms AsciiDoc {Model::Include} into the canonical
        # {CoreModel::Include}. The CoreModel node carries the parsed
        # options as a typed {CoreModel::IncludeOptions} instance plus
        # the raw bracket body for verbatim round-trip.
        class IncludeTransformer
          class << self
            # @param model [Coradoc::AsciiDoc::Model::Include]
            # @return [Coradoc::CoreModel::Include]
            def transform_include(model)
              options_hash = extract_options_hash(model.attributes)
              options = CoreModel::IncludeOptions.from_hash(options_hash)
              raw = extract_raw_options(model.attributes)

              CoreModel::Include.new(
                target: model.path.to_s,
                options: options,
                raw_options: raw,
                line_break: model.line_break.to_s
              )
            end

            private

            def extract_options_hash(attrs)
              return {} unless attrs.is_a?(Coradoc::AsciiDoc::Model::AttributeList)

              attrs.named.each_with_object({}) do |attr, hash|
                hash[attr.name.to_s] = serialize_named_value(attr.value)
              end
            end

            def serialize_named_value(value)
              case value
              when Array then value.map(&:to_s).join(';')
              else value.to_s
              end
            end

            def extract_raw_options(attrs)
              return '' unless attrs.is_a?(Coradoc::AsciiDoc::Model::AttributeList)

              adoc = attrs.to_adoc(show_empty: false).to_s
              adoc.gsub(/\A\[|\]\z/, '')
            end
          end
        end
      end
    end
  end
end
