# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ToCoreModelRegistrations
        Doc = ElementTransformers::DocumentTransformer
        Blk = ElementTransformers::BlockTransformer
        Lst = ElementTransformers::ListTransformer
        Inl = ElementTransformers::InlineTransformer
        Tbl = ElementTransformers::TableTransformer
        Oth = ElementTransformers::OtherTransformer

        class << self
          def register_all!
            register_document_transformers!
            register_block_transformers!
            register_list_transformers!
            register_inline_transformers!
            register_table_transformers!
            register_other_transformers!
          end

          private

          def register_document_transformers!
            Registry.register(
              Coradoc::AsciiDoc::Model::Document,
              ->(model) { Doc.transform_document(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Section,
              ->(model) { Doc.transform_section(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Paragraph,
              ->(model) { Blk.transform_paragraph(model) }
            )
          end

          def register_block_transformers!
            Registry.register_with_priority(
              Coradoc::AsciiDoc::Model::Block::SourceCode,
              ->(model) { Blk.transform_source_block(model) },
              priority: 10
            )

            {
              Coradoc::AsciiDoc::Model::Block::Quote => Coradoc::CoreModel::QuoteBlock,
              Coradoc::AsciiDoc::Model::Block::Example => Coradoc::CoreModel::ExampleBlock,
              Coradoc::AsciiDoc::Model::Block::Side => Coradoc::CoreModel::SidebarBlock,
              Coradoc::AsciiDoc::Model::Block::Literal => Coradoc::CoreModel::LiteralBlock,
              Coradoc::AsciiDoc::Model::Block::Open => Coradoc::CoreModel::OpenBlock,
              Coradoc::AsciiDoc::Model::Block::Pass => Coradoc::CoreModel::PassBlock
            }.each do |block_class, core_model_class|
              Registry.register_with_priority(
                block_class,
                ->(model) { Blk.transform_typed_block(model, core_model_class) },
                priority: 10
              )
            end

            Registry.register(
              Coradoc::AsciiDoc::Model::Block::Core,
              ->(model) { Blk.transform_block(model, model.delimiter.to_s) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::CommentBlock,
              lambda { |model|
                Coradoc::CoreModel::CommentBlock.new(
                  content: model.text.to_s
                )
              }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::CommentLine,
              lambda { |model|
                Coradoc::CoreModel::CommentLine.new(
                  text: model.text.to_s
                )
              }
            )
          end

          def register_list_transformers!
            Registry.register(
              Coradoc::AsciiDoc::Model::List::Unordered,
              ->(model) { Lst.transform_list(model, 'unordered') }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::List::Ordered,
              ->(model) { Lst.transform_list(model, 'ordered') }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::List::Definition,
              ->(model) { Lst.transform_list(model, 'definition') }
            )
          end

          def register_inline_transformers!
            [
              [Coradoc::AsciiDoc::Model::Inline::Bold, 'bold'],
              [Coradoc::AsciiDoc::Model::Inline::Italic, 'italic'],
              [Coradoc::AsciiDoc::Model::Inline::Monospace, 'monospace'],
              [Coradoc::AsciiDoc::Model::Inline::Highlight, 'highlight'],
              [Coradoc::AsciiDoc::Model::Inline::Strikethrough, 'strikethrough'],
              [Coradoc::AsciiDoc::Model::Inline::Subscript, 'subscript'],
              [Coradoc::AsciiDoc::Model::Inline::Superscript, 'superscript']
            ].each do |inline_class, format_type|
              Registry.register(
                inline_class,
                ->(model) { Inl.transform_inline(model, format_type) }
              )
            end

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::Underline,
              ->(model) { Inl.transform_inline_text(model, 'underline') }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::Link,
              ->(model) { Inl.transform_link(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::CrossReference,
              ->(model) { Inl.transform_cross_reference(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::Footnote,
              ->(model) { Inl.transform_inline_footnote(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::Stem,
              ->(model) { Inl.transform_stem(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::AttributeReference,
              lambda { |model|
                Coradoc::CoreModel::InlineElement.new(
                  format_type: 'attribute_reference',
                  content: "{#{model.name}}"
                )
              }
            )
          end

          def register_table_transformers!
            Registry.register(
              Coradoc::AsciiDoc::Model::Table,
              ->(model) { Tbl.transform_table(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::TableRow,
              ->(model) { Tbl.transform_table_row(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::TableCell,
              ->(model) { Tbl.transform_table_cell(model) }
            )
          end

          def register_other_transformers!
            Registry.register(
              Coradoc::AsciiDoc::Model::Term,
              ->(model) { Oth.transform_term(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Admonition,
              ->(model) { Oth.transform_admonition(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Image::BlockImage,
              ->(model) { Oth.transform_image(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Bibliography,
              ->(model) { Oth.transform_bibliography(model) }
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::BibliographyEntry,
              ->(model) { Oth.transform_bibliography_entry(model) }
            )

            [
              Coradoc::AsciiDoc::Model::TextElement,
              Coradoc::AsciiDoc::Model::Include,
              Coradoc::AsciiDoc::Model::Audio,
              Coradoc::AsciiDoc::Model::Video,
              Coradoc::AsciiDoc::Model::ContentList,
              Coradoc::AsciiDoc::Model::Tag
            ].each do |klass|
              Registry.register(klass, ->(model) { model })
            end

            [
              Coradoc::AsciiDoc::Model::LineBreak,
              Coradoc::AsciiDoc::Model::Break::PageBreak
            ].each do |klass|
              Registry.register(klass, ->(_model) {})
            end
          end
        end
      end
    end
  end
end

# Auto-register when this file is loaded
Coradoc::AsciiDoc::Transform::ToCoreModelRegistrations.register_all!
