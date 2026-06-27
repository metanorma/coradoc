# frozen_string_literal: true

module Coradoc
  module Mirror
    # OCP-compliant registry for Mirror node -> CoreModel transformation.
    #
    # Adding support for a new Mirror node type is purely additive:
    #
    #   # reverse_builder/<name>.rb
    #   require_relative 'base'
    #   module Coradoc::Mirror::ReverseBuilder
    #     class Figure < Base
    #       registers 'figure'
    #       def build(node) = CoreModel::Image.new(...)
    #     end
    #   end
    #
    # Then add a single `require_relative` for the new file below. No edits
    # to MirrorToCoreModel or any other existing class — the registry is
    # the single source of truth for "which type string maps to which
    # builder" (MECE).
    #
    # This file is the autoload target for the ReverseBuilder constant
    # (see coradoc/mirror.rb). Each Builder subclass lives in its own
    # file under reverse_builder/; eager-requiring them here populates
    # the REGISTRY at load time so every caller sees a full registry.
    # Mirror-level mark dispatch lives in MarkReverseBuilder
    # (mark_reverse_builder.rb).
    module ReverseBuilder
      # Not frozen: subclasses call `register` from their class body at
      # load time, and `registers` may fire late via autoload. Freezing
      # here breaks the first mirror-to-core round-trip after load.
      REGISTRY = {}

      module_function

      def register(type, builder_class)
        REGISTRY[type] = builder_class
      end

      def lookup(type)
        REGISTRY[type]
      end

      def registered_types
        REGISTRY.keys
      end

      # Base must load first — every subclass inherits from it. Then
      # eager-load each Builder so its `registers` call runs.
      require_relative 'reverse_builder/base'
      require_relative 'reverse_builder/document'
      require_relative 'reverse_builder/section'
      require_relative 'reverse_builder/header'
      require_relative 'reverse_builder/preamble'
      require_relative 'reverse_builder/sections'
      require_relative 'reverse_builder/paragraph'
      require_relative 'reverse_builder/code_block'
      require_relative 'reverse_builder/literal_block'
      require_relative 'reverse_builder/pass_block'
      require_relative 'reverse_builder/stem_block'
      require_relative 'reverse_builder/blockquote'
      require_relative 'reverse_builder/example'
      require_relative 'reverse_builder/sidebar'
      require_relative 'reverse_builder/open_block'
      require_relative 'reverse_builder/verse'
      require_relative 'reverse_builder/horizontal_rule'
      require_relative 'reverse_builder/frontmatter'
      require_relative 'reverse_builder/admonition'
      require_relative 'reverse_builder/bullet_list'
      require_relative 'reverse_builder/ordered_list'
      require_relative 'reverse_builder/list_item'
      require_relative 'reverse_builder/definition_list'
      require_relative 'reverse_builder/inline_text'
      require_relative 'reverse_builder/image'
      require_relative 'reverse_builder/figure'
      require_relative 'reverse_builder/caption'
      require_relative 'reverse_builder/include'
      require_relative 'reverse_builder/table'
      require_relative 'reverse_builder/table_head'
      require_relative 'reverse_builder/table_body'
      require_relative 'reverse_builder/table_row'
      require_relative 'reverse_builder/table_cell'
      require_relative 'reverse_builder/bibliography'
      require_relative 'reverse_builder/biblio_entry'
      require_relative 'reverse_builder/footnotes'
      require_relative 'reverse_builder/footnote_entry'
      require_relative 'reverse_builder/footnote_marker'
      require_relative 'reverse_builder/toc'
      require_relative 'reverse_builder/toc_entry'
      require_relative 'reverse_builder/text'
      require_relative 'reverse_builder/raw_inline'
      require_relative 'reverse_builder/soft_break'
      require_relative 'reverse_builder/generic_block'
    end
  end
end
