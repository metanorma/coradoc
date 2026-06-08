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

# Load all drops — each self-registers with DropFactory.
# Registration order doesn't matter (sorted by ancestor depth).
require 'coradoc/html/drop/annotation_drop'
require 'coradoc/html/drop/block_drop'
require 'coradoc/html/drop/list_block_drop'
require 'coradoc/html/drop/list_item_drop'
require 'coradoc/html/drop/table_drop'
require 'coradoc/html/drop/table_row_drop'
require 'coradoc/html/drop/table_cell_drop'
require 'coradoc/html/drop/image_drop'
require 'coradoc/html/drop/inline_element_drop'
require 'coradoc/html/drop/bibliography_entry_drop'
require 'coradoc/html/drop/bibliography_drop'
require 'coradoc/html/drop/toc_entry_drop'
require 'coradoc/html/drop/toc_drop'
require 'coradoc/html/drop/definition_item_drop'
require 'coradoc/html/drop/definition_list_drop'
require 'coradoc/html/drop/term_drop'
require 'coradoc/html/drop/footnote_drop'
require 'coradoc/html/drop/text_content_drop'
require 'coradoc/html/drop/document_drop'
