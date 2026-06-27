# frozen_string_literal: true

# Drop namespace — Liquid drop layer for template rendering.
#
# Each drop class is autoloaded from its own file (one class per file,
# mirroring the mirror/ReverseBuilder pattern). Eager loading is delegated
# to DropFactory.eager_load!, which triggers each autoload in dependency
# order so drops self-register with DropFactory at load time.
module Coradoc
  module Html
    module Drop
      autoload :Base, "#{__dir__}/drop/base"
      autoload :DropFactory, "#{__dir__}/drop/drop_factory"
      autoload :AnnotationDrop, "#{__dir__}/drop/annotation_drop"
      autoload :BlockDrop, "#{__dir__}/drop/block_drop"
      autoload :ListBlockDrop, "#{__dir__}/drop/list_block_drop"
      autoload :ListItemDrop, "#{__dir__}/drop/list_item_drop"
      autoload :TableDrop, "#{__dir__}/drop/table_drop"
      autoload :TableRowDrop, "#{__dir__}/drop/table_row_drop"
      autoload :TableCellDrop, "#{__dir__}/drop/table_cell_drop"
      autoload :ImageDrop, "#{__dir__}/drop/image_drop"
      # InlineElementDrop must load before RawInlineElementDrop (subclass).
      autoload :InlineElementDrop, "#{__dir__}/drop/inline_element_drop"
      autoload :RawInlineElementDrop, "#{__dir__}/drop/raw_inline_element_drop"
      autoload :BibliographyEntryDrop, "#{__dir__}/drop/bibliography_entry_drop"
      autoload :BibliographyDrop, "#{__dir__}/drop/bibliography_drop"
      autoload :TocEntryDrop, "#{__dir__}/drop/toc_entry_drop"
      autoload :TocDrop, "#{__dir__}/drop/toc_drop"
      autoload :DefinitionItemDrop, "#{__dir__}/drop/definition_item_drop"
      autoload :DefinitionListDrop, "#{__dir__}/drop/definition_list_drop"
      autoload :TermDrop, "#{__dir__}/drop/term_drop"
      autoload :FootnoteDrop, "#{__dir__}/drop/footnote_drop"
      autoload :TextContentDrop, "#{__dir__}/drop/text_content_drop"
      autoload :DocumentDrop, "#{__dir__}/drop/document_drop"
    end
  end
end

# Trigger eager load so every drop class body evaluates and self-registers.
Coradoc::Html::Drop::DropFactory.eager_load!
