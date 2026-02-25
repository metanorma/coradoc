# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Base class for attached elements in AsciiDoc documents.
      #
      # Attached elements are those that can be attached to other elements
      # such as list items or blocks. They include admonitions, paragraphs,
      # and other block types.
      #
      # This class provides the foundation for elements that can be
      # "attached" to parent elements in the document structure.
      #
      # @see Coradoc::AsciiDoc::Model::Admonition
      # @see Coradoc::AsciiDoc::Model::Paragraph
      # @see Coradoc::AsciiDoc::Model::Block::Core
      #
      class Attached < Base
      end
    end
  end
end
