# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Document < Base
          # Pre-compiled regex for performance
          LEADING_NEWLINES_REGEX = /\A\n+/

          def to_adoc(model, options_or_context = {})
            context = normalize_context(options_or_context)
            @model = model
            @context = context
            serialize_to_adoc
          end

          private

          attr_reader :context

          def serialize_to_adoc
            parts = []
            # Only add leading newline if we have sections but no header
            parts << "\n" if @model.sections && !@model.sections.empty? && !@model.header

            # Only serialize header if it has a non-empty title
            if @model.header.respond_to?(:title) && !@model.header.title.to_s.empty?
              parts << serialize_child(@model.header,
                                       @context)
            end

            # Only serialize document_attributes if it has data
            if @model.document_attributes.respond_to?(:data) &&
               @model.document_attributes.data && !@model.document_attributes.data.empty?
              parts << serialize_child(@model.document_attributes, @context)
            end

            # Serialize sections with last_element tracking
            parts << serialize_sections_with_last_element if @model.sections && !@model.sections.empty?
            result = parts.join

            # Clean up leading newlines when we have header
            if @model.header.respond_to?(:title) && !@model.header.title.to_s.empty?
              result = result.sub(LEADING_NEWLINES_REGEX,
                                  '')
            end
            result
          end

          def serialize_sections_with_last_element
            # Serialize all sections, marking the last one as the last element
            @model.sections.each_with_index.map do |section, index|
              child_context = context.for_child(index, @model.sections.length)
              serialize_child(section, child_context)
            end.join
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Document, Serializers::Document)
    end
  end
end
