# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Registers all default AsciiDoc -> CoreModel transformers
      module ToCoreModelRegistrations
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
              method_wrapper(:transform_document)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Section,
              method_wrapper(:transform_section)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Paragraph,
              method_wrapper(:transform_paragraph)
            )
          end

          def register_block_transformers!
            Registry.register_with_priority(
              Coradoc::AsciiDoc::Model::Block::SourceCode,
              METHOD_DISPATCH[:transform_source_block],
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
                typed_block_wrapper(core_model_class),
                priority: 10
              )
            end

            Registry.register(
              Coradoc::AsciiDoc::Model::Block::Core,
              block_model_wrapper
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::CommentBlock,
              lambda { |model|
                Coradoc::CoreModel::Block.new(
                  element_type: 'comment',
                  content: model.text.to_s
                )
              }
            )
          end

          def register_list_transformers!
            Registry.register(
              Coradoc::AsciiDoc::Model::List::Unordered,
              list_wrapper('unordered')
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::List::Ordered,
              list_wrapper('ordered')
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::List::Definition,
              list_wrapper('definition')
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
                inline_wrapper(format_type)
              )
            end

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::Underline,
              inline_text_wrapper('underline')
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::Link,
              method_wrapper(:transform_link)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::CrossReference,
              method_wrapper(:transform_cross_reference)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::Footnote,
              method_wrapper(:transform_inline_footnote)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::Stem,
              method_wrapper(:transform_stem)
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
              method_wrapper(:transform_table)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::TableRow,
              method_wrapper(:transform_table_row)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::TableCell,
              method_wrapper(:transform_table_cell)
            )
          end

          def register_other_transformers!
            Registry.register(
              Coradoc::AsciiDoc::Model::Term,
              method_wrapper(:transform_term)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Admonition,
              method_wrapper(:transform_admonition)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Image::BlockImage,
              method_wrapper(:transform_image)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::Bibliography,
              method_wrapper(:transform_bibliography)
            )

            Registry.register(
              Coradoc::AsciiDoc::Model::BibliographyEntry,
              method_wrapper(:transform_bibliography_entry)
            )

            # Passthrough types (no CoreModel equivalent)
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

            # Filtered types (layout-only, no CoreModel representation)
            [
              Coradoc::AsciiDoc::Model::LineBreak,
              Coradoc::AsciiDoc::Model::Break::PageBreak
            ].each do |klass|
              Registry.register(klass, ->(_model) { nil })
            end
          end

          METHOD_DISPATCH = {
            transform_document: ->(model) { ToCoreModel.transform_document(model) },
            transform_section: ->(model) { ToCoreModel.transform_section(model) },
            transform_paragraph: ->(model) { ToCoreModel.transform_paragraph(model) },
            transform_source_block: ->(model) { ToCoreModel.transform_source_block(model) },
            transform_link: ->(model) { ToCoreModel.transform_link(model) },
            transform_cross_reference: ->(model) { ToCoreModel.transform_cross_reference(model) },
            transform_inline_footnote: ->(model) { ToCoreModel.transform_inline_footnote(model) },
            transform_stem: ->(model) { ToCoreModel.transform_stem(model) },
            transform_table: ->(model) { ToCoreModel.transform_table(model) },
            transform_table_row: ->(model) { ToCoreModel.transform_table_row(model) },
            transform_table_cell: ->(model) { ToCoreModel.transform_table_cell(model) },
            transform_term: ->(model) { ToCoreModel.transform_term(model) },
            transform_admonition: ->(model) { ToCoreModel.transform_admonition(model) },
            transform_image: ->(model) { ToCoreModel.transform_image(model) },
            transform_bibliography: ->(model) { ToCoreModel.transform_bibliography(model) },
            transform_bibliography_entry: ->(model) { ToCoreModel.transform_bibliography_entry(model) }
          }.freeze

          def method_wrapper(method_name)
            METHOD_DISPATCH.fetch(method_name)
          end

          def typed_block_wrapper(klass)
            ->(model) { ToCoreModel.transform_typed_block(model, klass) }
          end

          def block_model_wrapper
            ->(model) { ToCoreModel.transform_block(model, model.delimiter.to_s) }
          end

          def list_wrapper(marker_type)
            ->(model) { ToCoreModel.transform_list(model, marker_type) }
          end

          def inline_wrapper(format_type)
            ->(model) { ToCoreModel.transform_inline(model, format_type) }
          end

          def inline_text_wrapper(format_type)
            ->(model) { ToCoreModel.transform_inline_text(model, format_type) }
          end
        end
      end
    end
  end
end

# Auto-register when this file is loaded
Coradoc::AsciiDoc::Transform::ToCoreModelRegistrations.register_all!
