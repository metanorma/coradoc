# frozen_string_literal: true

module Coradoc
  module Model
    module Serialization
      class AsciidocMappingRule < Lutaml::Model::MappingRule
        # Can be :content, or :attributes
        attr_reader :field_type

        def initialize(
          name,
          to:,
          render_nil: false,
          field_type: :attributes
        )
          super(name, to:, render_nil:)
          @field_type = field_type
        end

        def content?
          field_type == :content
        end

        def deep_dup
          self.class.new(
            name.dup,
            to: to.dup,
            render_nil: render_nil.dup,
            field_type:,
          )
        end
      end
    end
  end
end
