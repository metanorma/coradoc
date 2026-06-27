# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        class BlockTransformer
          class << self
            def transform_paragraph(para)
              children = ToCoreModel.transform_inline_content(para.content)

              Coradoc::CoreModel::ParagraphBlock.new(
                id: para.id,
                content: ToCoreModel.extract_text_content(para.content),
                children: children
              )
            end

            # Verbatim blocks (source, listing, literal, pass) must round-trip
            # their body byte-for-byte. Each source line becomes one content
            # line; we join with "\n" so whitespace, indentation, and blank
            # lines are preserved. Treating these as paragraphs would collapse
            # whitespace and join consecutive lines into a single flowing text.
            def transform_verbatim_block(block, klass, language_override: nil)
              non_break_lines = Array(block.lines).reject do |line|
                line.is_a?(Coradoc::AsciiDoc::Model::LineBreak) ||
                  line.is_a?(Coradoc::AsciiDoc::Model::Break::PageBreak)
              end
              content_lines = non_break_lines.map do |line|
                ToCoreModel.extract_text_content(line)
              end.join("\n")

              klass.new(
                id: block.id,
                title: ToCoreModel.extract_title_text(block.title),
                content: content_lines,
                language: language_override || ToCoreModel.extract_block_language(block)
              )
            end

            def transform_source_block(block)
              transform_verbatim_block(block, Coradoc::CoreModel::SourceBlock)
            end

            def transform_literal_block(block)
              transform_verbatim_block(block, Coradoc::CoreModel::LiteralBlock)
            end

            def transform_pass_block(block)
              style = first_positional_attr(block)
              return transform_stem_block(block, style) if STEM_STYLES.key?(style.to_s.downcase)

              transform_verbatim_block(block, Coradoc::CoreModel::PassBlock)
            end

            # AsciiDoc recognizes three STEM block styles. The default
            # `[stem]` resolves to LaTeX; the other two name their
            # interpreter explicitly. Single source of truth for the
            # style→language mapping.
            STEM_STYLES = {
              'stem' => 'latex',
              'latexmath' => 'latex',
              'asciimath' => 'asciimath'
            }.freeze

            def transform_stem_block(block, style)
              language = STEM_STYLES.fetch(style.to_s.downcase, 'latex')
              transform_verbatim_block(block, Coradoc::CoreModel::StemBlock,
                                       language_override: language)
            end

            # Dispatch entry point for any block whose AsciiDoc model carries
            # an attribute list (delimited blocks + open blocks). Per the
            # AsciiDoc spec, every delimited block accepts both admonition
            # labels and verbatim/stem casts in its attribute line. The cast
            # is resolved by +block_cast_semantic+ in MECE order:
            # admonition > stem > verbatim > fallback.
            def transform_with_admonition_check(block, native_class)
              semantic = block_cast_semantic(block)
              case semantic
              when :admonition
                transform_admonition_block(block, first_positional_attr(block))
              when :stem
                transform_stem_block(block, first_positional_attr(block))
              when :source
                transform_source_block(block)
              when :listing
                transform_listing_from_open(block)
              when :literal
                transform_literal_from_open(block)
              else
                transform_typed_block(block, native_class)
              end
            end

            def transform_example_block(block)
              transform_with_admonition_check(block, Coradoc::CoreModel::ExampleBlock)
            end

            def transform_sidebar_block(block)
              transform_with_admonition_check(block, Coradoc::CoreModel::SidebarBlock)
            end

            def transform_quote_block(block)
              transform_with_admonition_check(block, Coradoc::CoreModel::QuoteBlock)
            end

            # Open blocks (`--`) are generic containers. AsciiDoc allows
            # casting them to a different block type via positional
            # attributes: verbatim types (`[source]`, `[listing]`,
            # `[literal]`), STEM types (`[stem]`, `[latexmath]`,
            # `[asciimath]`), and admonition labels (`[NOTE]`, `[TIP]`,
            # `[WARNING]`, `[CAUTION]`, `[IMPORTANT]`). When such a cast
            # is present, the block behaves like the corresponding
            # delimited block. Anything else stays an OpenBlock.
            def transform_open_block(block)
              transform_with_admonition_check(block, Coradoc::CoreModel::OpenBlock)
            end

            VERBATILE_CAST_STYLES = %w[source listing literal].freeze

            # Resolve a delimited block's cast from its first positional
            # attribute. Single source of truth for the cast ladder used
            # by every block-form transformer (example/sidebar/quote/open).
            # Returns one of: :admonition, :stem, :source, :listing,
            # :literal, or nil (no cast — use the block's native class).
            def block_cast_semantic(block)
              style = first_positional_attr(block)
              return nil unless style

              style_str = style.to_s.downcase
              return :admonition if AdmonitionStyles.admonition?(style)
              return :stem if STEM_STYLES.key?(style_str)
              return style_str.to_sym if VERBATILE_CAST_STYLES.include?(style_str)

              nil
            end

            # Returns the first positional attribute on the block's
            # attribute list as a String, or nil if absent. Centralizes the
            # shape-walking that was previously inlined in
            # `transform_admonition_from_open` and `open_block_semantic`.
            def first_positional_attr(block)
              attrs = block.attributes
              return nil unless attrs.is_a?(Coradoc::AsciiDoc::Model::AttributeList)

              first = attrs.positional&.first
              return nil unless first.is_a?(Coradoc::AsciiDoc::Model::AttributeListAttribute)

              first.value.to_s
            end

            # Single admonition dispatch used by every block-form path
            # (example / sidebar / quote / pass / open). Builds an
            # AnnotationBlock with annotation_type set from the style and
            # the block's body lines joined into a single content string.
            # Type is canonicalised via AdmonitionStyles so every code path
            # (line admonition, block admonition, attribute-cast admonition)
            # produces the same uppercase key.
            def transform_admonition_block(block, type)
              canonical = AdmonitionStyles.canonicalize(type) || type.to_s
              content_lines = Array(block.lines).map { |line| ToCoreModel.extract_text_content(line) }.join("\n")
              Coradoc::CoreModel::AnnotationBlock.new(
                annotation_type: canonical,
                content: content_lines,
                title: ToCoreModel.extract_title_text(block.title)
              )
            end

            def transform_listing_from_open(block)
              transform_verbatim_block(block, Coradoc::CoreModel::ListingBlock)
            end

            def transform_literal_from_open(block)
              transform_verbatim_block(block, Coradoc::CoreModel::LiteralBlock)
            end

            def transform_block(block, semantic_type_or_delimiter)
              content_lines = ToCoreModel.extract_block_lines(block)
              semantic_type = if semantic_type_or_delimiter.is_a?(Symbol)
                                semantic_type_or_delimiter
                              else
                                ToCoreModel.asciidoc_delimiter_to_semantic(semantic_type_or_delimiter)
                              end

              Coradoc::CoreModel::Block.new(
                block_semantic_type: semantic_type,
                delimiter_type: semantic_type_or_delimiter.is_a?(String) ? semantic_type_or_delimiter : nil,
                id: block.id,
                title: ToCoreModel.extract_title_text(block.title),
                content: content_lines,
                language: ToCoreModel.extract_block_language(block)
              )
            end

            def transform_typed_block(block, klass, extra_attrs = {})
              raw_lines = Array(block.lines)
              has_nested_blocks = raw_lines.any? { |line| block_level_child?(line) }

              if has_nested_blocks
                children = raw_lines.reject do |line|
                  line.is_a?(Coradoc::AsciiDoc::Model::LineBreak) ||
                    line.is_a?(Coradoc::AsciiDoc::Model::Break::PageBreak)
                end.filter_map do |line|
                  result = ToCoreModel.transform(line)
                  next nil if result.nil?
                  next result if result.is_a?(Coradoc::CoreModel::Base)

                  text = ToCoreModel.extract_text_content(result)
                  next nil if text.nil? || text.strip.empty?

                  Coradoc::CoreModel::TextContent.new(text: text)
                end
                klass.new(
                  id: block.id,
                  title: ToCoreModel.extract_title_text(block.title),
                  children: children,
                  language: ToCoreModel.extract_block_language(block),
                  **extra_attrs
                )
              else
                paragraph_groups = group_block_lines_into_paragraphs(raw_lines)

                content_lines = paragraph_groups.map do |group|
                  ToCoreModel.extract_text_content(group)
                end.join("\n\n")

                children = paragraph_groups.map do |group|
                  inline = ToCoreModel.transform_inline_content(group)
                  inline = [Coradoc::CoreModel::TextContent.new(text: '')] if inline.empty?
                  Coradoc::CoreModel::ParagraphBlock.new(
                    content: ToCoreModel.extract_text_content(group),
                    children: Array(inline)
                  )
                end

                klass.new(
                  id: block.id,
                  title: ToCoreModel.extract_title_text(block.title),
                  content: content_lines,
                  children: children,
                  language: ToCoreModel.extract_block_language(block),
                  **extra_attrs
                )
              end
            end

            # AsciiDoc joins consecutive non-blank lines into one paragraph;
            # blank lines (parsed as Model::LineBreak) separate paragraphs.
            def group_block_lines_into_paragraphs(lines)
              groups = []
              current = []
              lines.each do |line|
                if line.is_a?(Coradoc::AsciiDoc::Model::LineBreak) ||
                   line.is_a?(Coradoc::AsciiDoc::Model::Break::PageBreak)
                  groups << current if current.any?
                  current = []
                else
                  current << line
                end
              end
              groups << current if current.any?
              groups
            end

            # A line that should be emitted as a direct child of the
            # enclosing block rather than joined into a paragraph sibling.
            # The AsciiDoc model layer declares level via `block_level?`
            # (true for Block::Core delimited blocks, BlockImage, Table,
            # List::Core, Section, CommentBlock, Attached). Inline content
            # (String, TextElement, LineBreak, PageBreak) returns false and
            # stays inside paragraphs.
            def block_level_child?(line)
              line.is_a?(Coradoc::AsciiDoc::Model::Base) && line.block_level?
            end
          end
        end
      end
    end
  end
end
