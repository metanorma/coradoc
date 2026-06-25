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
            def transform_verbatim_block(block, klass)
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
                language: ToCoreModel.extract_block_language(block)
              )
            end

            def transform_source_block(block)
              transform_verbatim_block(block, Coradoc::CoreModel::SourceBlock)
            end

            def transform_literal_block(block)
              transform_verbatim_block(block, Coradoc::CoreModel::LiteralBlock)
            end

            def transform_pass_block(block)
              transform_verbatim_block(block, Coradoc::CoreModel::PassBlock)
            end

            # Open blocks (`--`) are generic containers. AsciiDoc allows
            # casting them to a different block type via positional
            # attributes: verbatim types (`[source]`, `[listing]`,
            # `[literal]`) and admonition labels (`[NOTE]`, `[TIP]`,
            # `[WARNING]`, `[CAUTION]`, `[IMPORTANT]`). When such a cast
            # is present, the block behaves like the corresponding
            # delimited block. Anything else stays an OpenBlock.
            def transform_open_block(block)
              semantic = open_block_semantic(block)
              case semantic
              when :source_code
                transform_source_block(block)
              when :listing
                transform_listing_from_open(block)
              when :literal
                transform_literal_from_open(block)
              when :admonition
                transform_admonition_from_open(block)
              else
                transform_typed_block(block, Coradoc::CoreModel::OpenBlock)
              end
            end

            ADMONITION_TYPES = %w[note tip warning caution important].freeze

            def open_block_semantic(block)
              attrs = block.attributes
              return nil unless attrs.is_a?(Coradoc::AsciiDoc::Model::AttributeList)

              first = attrs.positional&.first
              return nil unless first.is_a?(Coradoc::AsciiDoc::Model::AttributeListAttribute)

              case first.value.to_s.downcase
              when 'source' then :source_code
              when 'listing' then :listing
              when 'literal' then :literal
              when *ADMONITION_TYPES then :admonition
              end
            end

            def transform_admonition_from_open(block)
              type = block.attributes.positional.first.value.to_s.downcase
              content_lines = Array(block.lines).map { |line| ToCoreModel.extract_text_content(line) }.join("\n")
              Coradoc::CoreModel::AnnotationBlock.new(
                annotation_type: type,
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
              has_nested_blocks = raw_lines.any?(Coradoc::AsciiDoc::Model::Block::Core)

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
          end
        end
      end
    end
  end
end
