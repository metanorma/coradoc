# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Post-processing pass that merges AsciiDoc callout annotation
      # paragraphs into the verbatim block they annotate.
      #
      # AsciiDoc callouts look like:
      #
      #   [source,ruby]
      #   ----
      #   get '/hi' do <1>
      #   ----
      #   <1> Returns hello world
      #
      # The parser emits the source block and the annotation as two
      # independent children. The CoreModel representation should attach
      # the annotation to the block as a typed Callout, so downstream
      # serializers can render them appropriately for each format.
      #
      # Single responsibility: take a flat list of transformed CoreModel
      # children, return a flat list with `<N>` paragraphs adjacent to a
      # SourceBlock / ListingBlock folded into that block's `callouts`.
      # Anything else is passed through untouched.
      class CalloutMerger
        ANNOTATION_LINE = /<(\d+)>\s*(.*?)\s*\z/
        ANNOTATION_SPLIT = /(?=<\d+>)/

        class << self
          def call(children)
            new.merge(Array(children))
          end
        end

        # Walks the input children left-to-right. When a paragraph whose
        # content is composed entirely of `<N> text` lines follows a
        # verbatim block (SourceBlock or ListingBlock), each `<N>` line
        # becomes a Callout attached to that block instead of a separate
        # paragraph.
        #
        # Annotations that do not follow a verbatim block are preserved
        # verbatim — they may be legitimate prose.
        def merge(children)
          children.each.with_object([]) do |child, result|
            annotations = extract_annotations(child)
            target = annotations && preceding_verbatim_block(result)
            if target
              target.callouts.concat(annotations)
            else
              result << child
            end
          end
        end

        private

        # Returns an Array of Callout if the paragraph is entirely
        # callout annotations, otherwise nil.
        def extract_annotations(child)
          return nil unless child.is_a?(Coradoc::CoreModel::ParagraphBlock)

          lines = split_annotation_lines(child.flat_text)
          return nil if lines.empty?

          callouts = lines.map do |line|
            match = line.match(ANNOTATION_LINE)
            match ? Coradoc::CoreModel::Callout.new(index: match[1].to_i, content: match[2]) : nil
          end
          return nil if callouts.any?(&:nil?)

          callouts
        end

        # Splits a paragraph into candidate annotation lines. Returns []
        # if any non-blank segment fails to look like an annotation.
        def split_annotation_lines(text)
          return [] if text.nil? || text.strip.empty?

          chunks = text.strip.split(ANNOTATION_SPLIT)
          chunks.map(&:strip).reject(&:empty?)
        end

        def preceding_verbatim_block(result)
          last = result.last
          return nil unless last.is_a?(Coradoc::CoreModel::SourceBlock) ||
                            last.is_a?(Coradoc::CoreModel::ListingBlock)

          last
        end
      end
    end
  end
end
