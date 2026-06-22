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

            def transform_source_block(block)
              non_break_lines = Array(block.lines).reject do |line|
                line.is_a?(Coradoc::AsciiDoc::Model::LineBreak) ||
                  line.is_a?(Coradoc::AsciiDoc::Model::Break::PageBreak)
              end
              content_lines = non_break_lines.map do |line|
                ToCoreModel.extract_text_content(line)
              end.join("\n")

              language = ToCoreModel.extract_block_language(block)

              Coradoc::CoreModel::SourceBlock.new(
                id: block.id,
                title: ToCoreModel.extract_title_text(block.title),
                content: content_lines,
                language: language
              )
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
              content_lines = Array(block.lines).map { |line| ToCoreModel.extract_text_content(line) }.join("\n")
              Coradoc::CoreModel::ListingBlock.new(
                id: block.id,
                title: ToCoreModel.extract_title_text(block.title),
                content: content_lines,
                language: ToCoreModel.extract_block_language(block)
              )
            end

            def transform_literal_from_open(block)
              content_lines = Array(block.lines).map { |line| ToCoreModel.extract_text_content(line) }.join("\n")
              Coradoc::CoreModel::LiteralBlock.new(
                id: block.id,
                title: ToCoreModel.extract_title_text(block.title),
                content: content_lines
              )
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
              lines = Array(block.lines).reject do |line|
                line.is_a?(Coradoc::AsciiDoc::Model::LineBreak) ||
                  line.is_a?(Coradoc::AsciiDoc::Model::Break::PageBreak)
              end

              has_nested_blocks = lines.any?(Coradoc::AsciiDoc::Model::Block::Core)

              if has_nested_blocks
                children = lines.filter_map do |line|
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
                content_lines = lines.map { |line| ToCoreModel.extract_text_content(line) }.join("\n")
                klass.new(
                  id: block.id,
                  title: ToCoreModel.extract_title_text(block.title),
                  content: content_lines,
                  language: ToCoreModel.extract_block_language(block),
                  **extra_attrs
                )
              end
            end
          end
        end
      end
    end
  end
end
