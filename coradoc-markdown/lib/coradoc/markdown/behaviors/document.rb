# frozen_string_literal: true

module Coradoc
  module Markdown
    module Behaviors
      # Hand-written behavior for Document: index access and construction.
      module Document
        def self.prepended(base)
          base.extend(ClassMethods)
        end

        # Constructors for Document.
        module ClassMethods
          # Create a document from an array of blocks
          def from_ast(elements)
            new(blocks: elements)
          end
        end

        # @param [Integer] index The index of the block to retrieve
        # @return [Coradoc::Markdown::Base] The block at the specified index
        def [](index)
          blocks[index]
        end

        # @param [Integer] index The index of the block to set
        # @param [Coradoc::Markdown::Base] value The block to set
        def []=(index, value)
          blocks[index] = value
        end
      end
    end
  end
end
