# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Registers all default AsciiDoc -> CoreModel transformers
      #
      # This module is automatically loaded and registers transformers
      # for all built-in AsciiDoc model types.
      #
      # Users can register custom transformers before or after these
      # defaults to override or extend behavior.
      #
      module ToCoreModelRegistrations
        class << self
          # Register all default transformers
          #
          # @return [void]
          def register_all!
            register_document_transformers!
            register_block_transformers!
            register_list_transformers!
            register_inline_transformers!
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
            # Register specific block types first (higher priority)
            [
              [Coradoc::AsciiDoc::Model::Block::SourceCode, 'source'],
              [Coradoc::AsciiDoc::Model::Block::Quote, 'quote'],
              [Coradoc::AsciiDoc::Model::Block::Example, 'example'],
              [Coradoc::AsciiDoc::Model::Block::Side, 'sidebar'],
              [Coradoc::AsciiDoc::Model::Block::Literal, 'literal'],
              [Coradoc::AsciiDoc::Model::Block::Open, 'open'],
              [Coradoc::AsciiDoc::Model::Block::Pass, 'pass']
            ].each do |block_class, delimiter_type|
              Registry.register_with_priority(
                block_class,
                block_wrapper(delimiter_type),
                priority: 10
              )
            end

            # Generic block handler (lower priority, catches remaining Block::Core subclasses)
            Registry.register(
              Coradoc::AsciiDoc::Model::Block::Core,
              ->(model) { ToCoreModel.send(:transform_block, model, model.delimiter) }
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
            # Standard inline formatting
            [
              [Coradoc::AsciiDoc::Model::Inline::Bold, 'bold'],
              [Coradoc::AsciiDoc::Model::Inline::Italic, 'italic'],
              [Coradoc::AsciiDoc::Model::Inline::Monospace, 'monospace'],
              [Coradoc::AsciiDoc::Model::Inline::Highlight, 'highlight']
            ].each do |inline_class, format_type|
              Registry.register(
                inline_class,
                inline_wrapper(format_type)
              )
            end

            # Link has special handling
            Registry.register(
              Coradoc::AsciiDoc::Model::Inline::Link,
              method_wrapper(:transform_link)
            )
          end

          def register_other_transformers!
            Registry.register(
              Coradoc::AsciiDoc::Model::Table,
              method_wrapper(:transform_table)
            )

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
          end

          # Helper to wrap a method call
          def method_wrapper(method_name)
            ->(model) { ToCoreModel.send(method_name, model) }
          end

          # Helper to wrap block transformation with delimiter type
          def block_wrapper(delimiter_type)
            ->(model) { ToCoreModel.send(:transform_block, model, delimiter_type) }
          end

          # Helper to wrap list transformation with marker type
          def list_wrapper(marker_type)
            ->(model) { ToCoreModel.send(:transform_list, model, marker_type) }
          end

          # Helper to wrap inline transformation with format type
          def inline_wrapper(format_type)
            ->(model) { ToCoreModel.send(:transform_inline, model, format_type) }
          end
        end
      end
    end
  end
end

# Auto-register when this file is loaded
Coradoc::AsciiDoc::Transform::ToCoreModelRegistrations.register_all!
