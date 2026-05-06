# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Registers all default CoreModel -> AsciiDoc transformers
      module FromCoreModelRegistrations
        class << self
          def register_all!
            register_structural_transformers!
            register_block_transformers!
            register_list_transformers!
            register_inline_transformers!
            register_other_transformers!
          end

          private

          def register_structural_transformers!
            Registry.register(
              Coradoc::CoreModel::StructuralElement,
              ->(model) { FromCoreModel.transform_structural_element(model) }
            )
          end

          def register_block_transformers!
            Registry.register_with_priority(
              Coradoc::CoreModel::AnnotationBlock,
              ->(model) { FromCoreModel.transform_annotation(model) },
              priority: 10
            )

            Registry.register(
              Coradoc::CoreModel::Block,
              ->(model) { FromCoreModel.transform_block(model) }
            )
          end

          def register_list_transformers!
            Registry.register(
              Coradoc::CoreModel::ListBlock,
              ->(model) { FromCoreModel.transform_list(model) }
            )

            Registry.register(
              Coradoc::CoreModel::ListItem,
              ->(model) { FromCoreModel.transform_list_item(model) }
            )

            Registry.register(
              Coradoc::CoreModel::DefinitionList,
              ->(model) { FromCoreModel.transform_definition_list(model) }
            )

            Registry.register(
              Coradoc::CoreModel::DefinitionItem,
              ->(model) { FromCoreModel.transform_definition_item(model) }
            )
          end

          def register_inline_transformers!
            Registry.register(
              Coradoc::CoreModel::InlineElement,
              ->(model) { FromCoreModel.transform_inline(model) }
            )
          end

          def register_other_transformers!
            Registry.register(
              Coradoc::CoreModel::Table,
              ->(model) { FromCoreModel.transform_table(model) }
            )

            Registry.register(
              Coradoc::CoreModel::Term,
              ->(model) { FromCoreModel.transform_term(model) }
            )

            Registry.register(
              Coradoc::CoreModel::Image,
              ->(model) { FromCoreModel.transform_image(model) }
            )

            Registry.register(
              Coradoc::CoreModel::Footnote,
              ->(model) { FromCoreModel.transform_footnote(model) }
            )

            Registry.register(
              Coradoc::CoreModel::FootnoteReference,
              ->(model) { FromCoreModel.transform_footnote_reference(model) }
            )

            Registry.register(
              Coradoc::CoreModel::Abbreviation,
              ->(model) { FromCoreModel.transform_abbreviation(model) }
            )

            Registry.register(
              Coradoc::CoreModel::Toc,
              ->(model) { FromCoreModel.transform_toc(model) }
            )

            Registry.register(
              Coradoc::CoreModel::TocEntry,
              ->(model) { FromCoreModel.transform_toc_entry(model) }
            )

            Registry.register(
              Coradoc::CoreModel::Bibliography,
              ->(model) { FromCoreModel.transform_bibliography(model) }
            )

            Registry.register(
              Coradoc::CoreModel::BibliographyEntry,
              ->(model) { FromCoreModel.transform_bibliography_entry(model) }
            )
          end
        end
      end
    end
  end
end

# Auto-register when this file is loaded
Coradoc::AsciiDoc::Transform::FromCoreModelRegistrations.register_all!
