# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Table < Base
          def to_adoc(model, options_or_context = {})
            @model = model
            context = normalize_context(options_or_context)
            _anchor = @model.anchor.nil? ? '' : "#{serialize_child(@model.anchor)}\n"
            _attrs = @model.attrs.to_s.empty? ? '' : "#{serialize_child(@model.attrs)}\n"
            _title = @model.title.nil? || @model.title.empty? ? '' : ".#{serialize_child(@model.title)}\n"
            _content = @model.rows.map { |row| serialize_child(row) }.join

            # Blank-line separation after the table so a following
            # block never glues onto the closer (#151) — same
            # convention as the paragraph serializer, suppressed for
            # the document's last element.
            separator = context.last_element ? '' : "\n"
            "\n\n#{_anchor}#{_attrs}#{_title}|===\n#{_content}|===\n#{separator}"
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Table, Serializers::Table)
    end
  end
end
