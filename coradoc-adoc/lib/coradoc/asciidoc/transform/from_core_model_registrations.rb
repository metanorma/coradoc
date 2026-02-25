# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Registers all default CoreModel -> AsciiDoc transformers
      #
      # This module is automatically loaded and registers transformers
      # for all built-in CoreModel types to convert them to AsciiDoc models.
      #
      # Users can register custom transformers before or after these
      # defaults to override or extend behavior.
      #
      module FromCoreModelRegistrations
        class << self
          # Register all default transformers
          #
          # @return [void]
          def register_all!
            register_structural_transformers!
            register_block_transformers!
            register_list_transformers!
            register_inline_transformers!
            register_other_transformers!
          end

          private

          def register_structural_transformers!
            # StructuralElement handles both document and section types
            Registry.register(
              Coradoc::CoreModel::StructuralElement,
              ->(model) { FromCoreModel.send(:transform_structural_element, model) }
            )
          end

          def register_block_transformers!
            # AnnotationBlock must be registered before Block (it's a subclass)
            Registry.register_with_priority(
              Coradoc::CoreModel::AnnotationBlock,
              ->(model) { FromCoreModel.send(:transform_annotation, model) },
              priority: 10
            )

            # Generic Block handler (lower priority)
            Registry.register(
              Coradoc::CoreModel::Block,
              ->(model) { FromCoreModel.send(:transform_block, model) }
            )
          end

          def register_list_transformers!
            Registry.register(
              Coradoc::CoreModel::ListBlock,
              ->(model) { FromCoreModel.send(:transform_list, model) }
            )

            Registry.register(
              Coradoc::CoreModel::ListItem,
              ->(model) { FromCoreModel.send(:transform_list_item, model) }
            )
          end

          def register_inline_transformers!
            Registry.register(
              Coradoc::CoreModel::InlineElement,
              ->(model) { FromCoreModel.send(:transform_inline, model) }
            )
          end

          def register_other_transformers!
            Registry.register(
              Coradoc::CoreModel::Table,
              ->(model) { FromCoreModel.send(:transform_table, model) }
            )

            Registry.register(
              Coradoc::CoreModel::Term,
              ->(model) { FromCoreModel.send(:transform_term, model) }
            )

            Registry.register(
              Coradoc::CoreModel::Image,
              ->(model) { FromCoreModel.send(:transform_image, model) }
            )
          end
        end
      end
    end
  end
end

# Auto-register when this file is loaded
Coradoc::AsciiDoc::Transform::FromCoreModelRegistrations.register_all!
