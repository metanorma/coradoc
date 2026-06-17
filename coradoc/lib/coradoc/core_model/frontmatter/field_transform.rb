# frozen_string_literal: true

module Coradoc
  module CoreModel
    class FrontmatterBlock
      # OCP registry for semantic field transforms applied during
      # format conversion (e.g., `authors` array → `author` string when
      # emitting Markdown for Jekyll).
      #
      # Transforms are directional + format-specific. Each transform
      # declares when it applies and how it rewrites the block's data
      # hash. Never mutates the input — always returns a new block.
      module FieldTransform
        # Base class. Override #applies? and #apply in subclasses.
        class Base
          # Override: return true if this transform should fire for the
          # given direction (:to_format or :from_format) and format
          # (:markdown, :asciidoc, etc.).
          def applies?(direction:, format:) # rubocop:disable Lint/UnusedMethodArgument
            false
          end

          # Override: receive a FrontmatterBlock, return a (possibly new)
          # FrontmatterBlock. Never mutate the input.
          def apply(block)
            block
          end

          protected

          # Helper: produce a new FrontmatterBlock with transformed data.
          def rebuild(block, data:)
            FrontmatterBlock.new(schema: block.schema, data: data)
          end
        end

        class Registry
          DEFAULT = new

          def initialize
            @transforms = []
          end

          def register(transform_class)
            @transforms << transform_class unless @transforms.include?(transform_class)
          end

          def count
            @transforms.size
          end

          # Apply all registered transforms whose #applies? returns true.
          # Returns a FrontmatterBlock (possibly the same one).
          def apply_all(block, direction:, format:)
            return block unless block.is_a?(FrontmatterBlock)

            @transforms.reduce(block) do |current, klass|
              transform = klass.new
              if transform.applies?(direction: direction, format: format)
                transform.apply(current)
              else
                current
              end
            end
          end
        end
      end
    end
  end
end
