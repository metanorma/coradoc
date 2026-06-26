# frozen_string_literal: true

module Coradoc
  module Reference
    module Catalog
      # Indexes one CoreModel document. Walks the tree once at
      # construction; indexes every node carrying an +id+ by its anchor
      # Address, plus the document itself by an optional path Address.
      #
      #   catalog = Catalog::Local.from_doc(doc, path: "ELF-5005-1")
      #   catalog.lookup(Address.parse("ELF-5005-1"))        # => doc
      #   catalog.lookup(Address.parse("sec-3"))             # => section
      class Local
        include Catalog::Protocol

        attr_reader :document, :document_path

        def initialize(document:, document_path: nil, index: nil)
          @document = document
          @document_path = document_path
          @index = index || MemoryIndex.new
          populate! unless index
        end

        class << self
          def from_doc(document, path: nil)
            new(document: document, document_path: path)
          end
        end

        def lookup(address)
          @index.lookup(address)
        end

        def ambiguous?(address)
          @index.ambiguous?(address)
        end

        def each_pair(&)
          @index.each_pair(&)
        end

        def recognizes_scheme?(scheme)
          return true if scheme.to_sym == :anchor
          return true if scheme.to_sym == :path && document_path
          return true if scheme.to_sym == :scoped_path && document_path&.include?(':')

          @index.recognizes_scheme?(scheme)
        end

        private

        def populate!
          index_document_root!
          walk(document)
        end

        def index_document_root!
          return unless document_path

          address = Coradoc::Reference::Address.parse(document_path, hint: path_hint)
          @index.add(address, document)
        end

        def path_hint
          document_path.include?(':') ? :scoped_path : :path
        end

        def walk(node)
          return unless node.is_a?(Coradoc::CoreModel::Base)

          index_node!(node)
          walk_children(node)
        end

        def index_node!(node)
          return unless node.id

          address = Coradoc::Reference::Address.new(
            scheme: 'anchor',
            target: node.id
          )
          @index.add(address, node)
        end

        def walk_children(node)
          return unless node.is_a?(Coradoc::CoreModel::HasChildren)

          children = node.children
          return if children.nil? || children.empty?

          children.each { |child| walk(child) }
        end
      end
    end
  end
end
