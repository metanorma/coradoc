# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Marker module for "this model exposes a +children+ collection".
    #
    # Including this is the canonical way to opt a CoreModel class into
    # children-based traversal. Downstream code (e.g. mirror's
    # CoreModelToMirror#element_children) dispatches on +is_a?(HasChildren)+
    # rather than enumerating subclasses, so adding a new children-bearing
    # class is purely additive (OCP).
    #
    # ChildrenContent (the mixed-content auto-wrap behavior) includes
    # HasChildren, so every class that mixes in ChildrenContent also
    # satisfies HasChildren. Classes that carry typed block children
    # only (StructuralElement, etc.) include HasChildren directly.
    module HasChildren
      def has_children?
        true
      end
    end
  end
end
