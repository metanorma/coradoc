# frozen_string_literal: true

module Coradoc
  module Mirror
    # Doc-level structural partitioning of built Mirror nodes into the
    # [preface, sections, *bibliography, *trailing] shape per the
    # @metanorma/mirror JS contract.
    #
    # Extracted from Handlers::Structural so handlers stay focused on
    # mapping one CoreModel element → one Mirror node, while the
    # post-emission restructure lives in its own module (MECE).
    module Partitioner
      # Mirror node types that count as "section" for partition bucketing.
      # Includes the legacy 'section' type plus all JS SECTION_TYPES
      # (clause, annex, abstract, foreword, introduction, terms,
      # definitions, references, content_section, acknowledgements).
      SECTION_TYPES = Set.new(%w[
        clause annex content_section abstract foreword introduction
        acknowledgements terms definitions references section
      ]).freeze

      module_function

      # Single-pass state machine over a flat list of built Mirror nodes.
      #
      # Loose blocks before any section appears → :preface.
      # Once a section appears → :sections; subsequent loose blocks also
      # go into :sections (preserves document order).
      # Once a bibliography appears → :trailing.
      # Footnotes blocks always go into :trailing regardless of state.
      #
      # @param children [Array<Node>] flat list of built Mirror nodes
      # @return [Hash{Symbol=>Array<Node>}] buckets under :preface,
      #   :sections, :bibliography, :trailing
      def partition(children)
        buckets = { preface: [], sections: [], bibliography: [], trailing: [] }
        state = :preface

        children.each do |child|
          case child.type
          when 'preface'
            buckets[:preface].concat(child.content || [])
          when 'bibliography'
            buckets[:bibliography] << child
            state = :trailing
          else
            if SECTION_TYPES.include?(child.type)
              buckets[:sections] << child
              state = :sections
            elsif child.type == 'footnotes'
              buckets[:trailing] << child
            else
              buckets[state] << child
            end
          end
        end

        buckets
      end
    end
  end
end
