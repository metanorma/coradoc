# frozen_string_literal: true

module Coradoc
  module Markdown
    module Transform
      module BlockTransformer
        class << self
          def transform_block(block)
            semantic = block.resolve_semantic_type || markdown_delimiter_to_semantic(block.delimiter_type)

            case semantic
            when :paragraph
              transform_paragraph(block)
            when :comment
              transform_comment_block(block)
            when :source_code, :listing, :literal
              transform_code_block(block)
            when :quote
              transform_blockquote(block)
            when :verse
              transform_verse_block(block)
            when :horizontal_rule
              transform_horizontal_rule(block)
            when :pass
              transform_pass_block(block)
            when :example
              transform_example_block(block)
            when :sidebar
              transform_sidebar_block(block)
            when :open
              transform_open_block(block)
            when :reviewer
              transform_reviewer_block(block)
            else
              transform_paragraph(block)
            end
          end

          def transform_paragraph(block)
            content = block.renderable_content
            has_structured = content.is_a?(Array) && content.any? { |c| !c.is_a?(CoreModel::TextContent) }
            if has_structured
              children = content.map { |c| transform_content_node(c) }
              Coradoc::Markdown::Paragraph.new(text: block.flat_text, children: children)
            else
              Coradoc::Markdown::Paragraph.new(text: block.flat_text)
            end
          end

          # Transform a content node that could be inline text, an
          # inline element, or a block-level element (e.g. a SourceBlock
          # inside a list item via AsciiDoc continuation).
          def transform_content_node(element)
            case element
            when CoreModel::InlineElement
              InlineTransformer.transform_inline(element)
            when CoreModel::TextContent
              element.text
            when CoreModel::Base
              FromCoreModel.transform(element)
            when String
              element
            else
              element.to_s
            end
          end

          # Kept as public alias for backward compat with existing callers
          alias transform_inline_content transform_content_node

          def markdown_delimiter_to_semantic(delimiter)
            case delimiter
            when '```', '~' then :source_code
            when '>' then :quote
            when '---', '***', '___' then :horizontal_rule
            when '++++' then :pass
            end
          end

          def transform_code_block(block)
            Coradoc::Markdown::CodeBlock.new(
              code: block.content.to_s,
              language: block.language
            )
          end

          def transform_blockquote(block)
            content = block.flat_text
            Coradoc::Markdown::Blockquote.new(content: content)
          end

          def transform_verse_block(block)
            Coradoc::Markdown::Blockquote.new(content: block.flat_text)
          end

          def transform_horizontal_rule(_block)
            Coradoc::Markdown::HorizontalRule.new
          end

          def transform_example_block(block)
            content = block.flat_text
            Coradoc::Markdown::Blockquote.new(content: content)
          end

          def transform_sidebar_block(block)
            content = block.flat_text
            Coradoc::Markdown::Paragraph.new(text: content)
          end

          def transform_open_block(block)
            if block.children && !block.children.empty?
              block.children.map { |c| FromCoreModel.transform(c) }
            else
              content = block.flat_text
              Coradoc::Markdown::Paragraph.new(text: content)
            end
          end

          def transform_reviewer_block(block)
            text = block.flat_text
            Coradoc::Markdown::Paragraph.new(
              text: "**#{block.annotation_type}:** #{text}"
            )
          end

          def transform_annotation_block(annotation)
            text = annotation.flat_text
            Coradoc::Markdown::Paragraph.new(
              text: "**#{annotation.annotation_type}:** #{text}"
            )
          end

          def transform_comment_block(block)
            Coradoc::Markdown::Extension.comment(block.content.to_s)
          end

          def transform_pass_block(block)
            Coradoc::Markdown::Extension.nomarkdown(block.content.to_s)
          end
        end

        # Register subclasses first so they match before CoreModel::Block
        FromCoreModel.register(CoreModel::AnnotationBlock, method(:transform_annotation_block))
        FromCoreModel.register(CoreModel::ParagraphBlock, method(:transform_paragraph))
        FromCoreModel.register(CoreModel::SourceBlock, method(:transform_code_block))
        FromCoreModel.register(CoreModel::ListingBlock, method(:transform_code_block))
        FromCoreModel.register(CoreModel::LiteralBlock, method(:transform_code_block))
        FromCoreModel.register(CoreModel::QuoteBlock, method(:transform_blockquote))
        FromCoreModel.register(CoreModel::VerseBlock, method(:transform_verse_block))
        FromCoreModel.register(CoreModel::HorizontalRuleBlock, method(:transform_horizontal_rule))
        FromCoreModel.register(CoreModel::PassBlock, method(:transform_pass_block))
        FromCoreModel.register(CoreModel::ExampleBlock, method(:transform_example_block))
        FromCoreModel.register(CoreModel::SidebarBlock, method(:transform_sidebar_block))
        FromCoreModel.register(CoreModel::OpenBlock, method(:transform_open_block))
        FromCoreModel.register(CoreModel::ReviewerBlock, method(:transform_reviewer_block))
        FromCoreModel.register(CoreModel::CommentBlock, method(:transform_comment_block))

        # Generic block fallback
        FromCoreModel.register(CoreModel::Block, method(:transform_block))
      end
    end
  end
end
