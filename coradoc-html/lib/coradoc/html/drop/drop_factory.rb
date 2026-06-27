# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      module DropFactory
        @registry = []

        def self.register(model_class, drop_class)
          @registry << [model_class, drop_class]
          sort_registry!
        end

        def self.create(obj)
          return nil if obj.nil?
          return obj.map { |o| create(o) } if obj.is_a?(Array)
          return Escape.escape_html(obj) if obj.is_a?(String)
          return obj.to_s if obj.is_a?(Numeric) || obj.is_a?(TrueClass) || obj.is_a?(FalseClass)

          pair = lookup_pair(obj)
          return pair.last.new(obj) if pair

          Escape.escape_html(obj.to_s)
        end

        def self.drop_class_for(model)
          pair = lookup_pair(model)
          pair&.last
        end

        def self.template_type_for(model)
          drop = drop_class_for(model)
          drop&.new(model)&.template_type
        end

        # Walk the Drop namespace and trigger each declared autoload so the
        # drop class body evaluates and self-registers. Called eagerly from
        # drop.rb after autoloads are declared.
        EAGER_LOAD_ORDER = %i[Base DropFactory AnnotationDrop BlockDrop ListBlockDrop ListItemDrop
                              TableDrop TableRowDrop TableCellDrop ImageDrop InlineElementDrop RawInlineElementDrop
                              BibliographyEntryDrop BibliographyDrop TocEntryDrop TocDrop DefinitionItemDrop
                              DefinitionListDrop TermDrop FootnoteDrop TextContentDrop DocumentDrop].freeze
        private_constant :EAGER_LOAD_ORDER

        def self.eager_load!
          EAGER_LOAD_ORDER.each { |sym| Drop.const_get(sym) }
          true
        end

        class << self
          private

          def lookup_pair(obj)
            @registry.find { |klass, _drop_class| obj.is_a?(klass) }
          end

          def sort_registry!
            @registry.sort_by! { |klass, _| -klass.ancestors.length }
          end
        end
      end
    end
  end
end
