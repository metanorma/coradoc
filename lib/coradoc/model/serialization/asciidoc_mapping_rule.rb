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
          render_default: false,
          with: {},
          delegate: nil,
          field_type: :attributes,
          transform: {}
        )
          super(name,
                to: to,
                render_nil: render_nil,
                render_default: render_default,
                with: with,
                delegate: delegate,
                transform: transform)
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
            with: Utils.deep_dup(custom_methods),
            delegate: delegate,
            field_type: field_type,
            transform: Utils.deep_dup(transform),
          )
        end
      end
    end
  end
end
