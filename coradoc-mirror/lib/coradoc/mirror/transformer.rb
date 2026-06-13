# frozen_string_literal: true

module Coradoc
  module Mirror
    # Bidirectional facade for CoreModel ↔ Mirror transformation.
    #
    # Delegates to CoreModelToMirror (forward) and MirrorToCoreModel (reverse).
    #
    # @example Forward transformation
    #   transformer = Coradoc::Mirror::Transformer.new
    #   mirror_doc = transformer.from_core_model(document)
    #
    # @example Reverse transformation
    #   core_doc = transformer.to_core_model(mirror_doc)
    #
    class Transformer
      def initialize(registry: Coradoc::Mirror.default_registry)
        @registry = registry
      end

      # Convert CoreModel document to Mirror node tree.
      #
      # @param document [CoreModel::Base] CoreModel document
      # @return [Node::Document] mirror document root
      def from_core_model(document)
        CoreModelToMirror.new(registry: @registry).call(document)
      end

      # Convert Mirror node tree to CoreModel document.
      #
      # @param mirror_node [Node] mirror document root
      # @return [CoreModel::Base] CoreModel document
      def to_core_model(mirror_node)
        MirrorToCoreModel.new.call(mirror_node)
      end
    end
  end
end
