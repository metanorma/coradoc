# frozen_string_literal: true

module Coradoc
  module IncludeSelectors
    # Shifts section heading levels in a parsed CoreModel subtree.
    #
    # Applied AFTER parsing — works on SectionElement instances. Two modes:
    #
    #   relative (+N / -N)   every SectionElement#level += delta
    #   absolute (N)         the FIRST section's level becomes N, and
    #                         descendants shift by the same delta so their
    #                         relative structure is preserved (asciidoctor
    #                         behavior).
    #
    # The processor passes a freshly-parsed subtree to this selector, so
    # there are no external references and in-place mutation is safe.
    module LevelOffset
      # @param core [Coradoc::CoreModel::Base] freshly parsed — mutated
      # @param options [Coradoc::CoreModel::IncludeOptions]
      # @return [Coradoc::CoreModel::Base] the same core (mutated)
      def self.call(core, options:)
        offset = options.leveloffset
        return core if offset.nil?

        first_level = find_first_level(core)
        actual_delta = compute_actual_delta(offset, first_level)
        return core if actual_delta.zero?

        walk_and_shift(core, actual_delta)
        core
      end

      class << self
        private

        def compute_actual_delta(offset, first_level)
          case offset.mode
          when 'relative' then offset.delta
          when 'absolute'
            return 0 if first_level.nil?

            offset.delta - first_level
          else 0
          end
        end

        def find_first_level(node)
          case node
          when Coradoc::CoreModel::SectionElement
            node.level || 1
          when Coradoc::CoreModel::StructuralElement, Coradoc::CoreModel::Block
            walk_for_first_level(node.children)
          else
            nil
          end
        end

        def walk_for_first_level(children)
          return nil if children.nil?

          children.each do |child|
            lvl = find_first_level(child)
            return lvl unless lvl.nil?
          end
          nil
        end

        def walk_and_shift(node, delta)
          case node
          when Coradoc::CoreModel::SectionElement
            node.level = [(node.level || 1) + delta, 0].max
            walk_children(node, delta)
          when Coradoc::CoreModel::StructuralElement, Coradoc::CoreModel::Block
            walk_children(node, delta)
          end
        end

        def walk_children(node, delta)
          return if node.children.nil?

          node.children.each { |c| walk_and_shift(c, delta) }
        end
      end
    end
  end
end
