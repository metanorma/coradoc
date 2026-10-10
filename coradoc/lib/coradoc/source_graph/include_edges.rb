# frozen_string_literal: true

module Coradoc
  module SourceGraph
    # Extracts include edges from a materialized CoreModel: every
    # {CoreModel::Include} link node contributes one edge. Targets
    # resolve relative to the including file's directory, matching
    # ResolveIncludes semantics (SPEC 7.2).
    module IncludeEdges
      module_function

      # @param core [CoreModel::Base] materialized CoreModel of the
      #   including document
      # @param base_dir [String] directory of the including file
      # @return [Array<String>] absolute, expanded target paths
      def targets(core, base_dir:)
        collect([core], []).map { |target| File.expand_path(target, base_dir) }
      end

      def collect(nodes, acc)
        Array(nodes).flatten.each do |node|
          case node
          when CoreModel::Include
            acc << node.target if node.target
          when CoreModel::Base
            collect(node.children, acc) if node.is_a?(CoreModel::HasChildren)
          end
        end
        acc
      end
    end
  end
end
