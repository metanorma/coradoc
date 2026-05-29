# frozen_string_literal: true

require_relative 'base'
require_relative '../escape'
require_relative 'text_content_drop'
require_relative 'inline_element_drop'
require_relative 'block_drop'
require_relative 'document_drop'
require_relative 'list_block_drop'
require_relative 'list_item_drop'
require_relative 'table_drop'
require_relative 'table_row_drop'
require_relative 'table_cell_drop'
require_relative 'image_drop'
require_relative 'annotation_drop'
require_relative 'bibliography_drop'
require_relative 'bibliography_entry_drop'
require_relative 'toc_drop'
require_relative 'toc_entry_drop'
require_relative 'definition_list_drop'
require_relative 'definition_item_drop'
require_relative 'term_drop'
require_relative 'footnote_drop'

module Coradoc
  module Html
    module Drop
      # Factory for creating the correct Drop subclass from a CoreModel instance.
      #
      # Uses `is_a?` type checks in order from most-specific to least-specific.
      # No `respond_to?`, no `send`, no `instance_variable_get/set`.
      module DropFactory
        TYPE_MAP = [
          [CoreModel::AnnotationBlock, AnnotationDrop],
          [CoreModel::Block, BlockDrop],
          [CoreModel::ListBlock, ListBlockDrop],
          [CoreModel::ListItem, ListItemDrop],
          [CoreModel::Table, TableDrop],
          [CoreModel::TableRow, TableRowDrop],
          [CoreModel::TableCell, TableCellDrop],
          [CoreModel::Image, ImageDrop],
          [CoreModel::InlineElement, InlineElementDrop],
          [CoreModel::BibliographyEntry, BibliographyEntryDrop],
          [CoreModel::Bibliography, BibliographyDrop],
          [CoreModel::TocEntry, TocEntryDrop],
          [CoreModel::Toc, TocDrop],
          [CoreModel::DefinitionItem, DefinitionItemDrop],
          [CoreModel::DefinitionList, DefinitionListDrop],
          [CoreModel::Term, TermDrop],
          [CoreModel::FootnoteReference, FootnoteDrop],
          [CoreModel::Footnote, FootnoteDrop],
          [CoreModel::TextContent, TextContentDrop],
          [CoreModel::StructuralElement, DocumentDrop]
        ].freeze

        # Create a Drop for the given object.
        #
        # @param obj [Object] CoreModel instance, String, Array, or primitive
        # @return [Drop::Base, String, Array, nil]
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
            TYPE_MAP.find { |klass, _drop_class| obj.is_a?(klass) }
          end
        end
      end
    end
  end
end
