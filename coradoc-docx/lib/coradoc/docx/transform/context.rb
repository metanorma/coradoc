# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      # Shared context for a single OOXML → CoreModel transform pass.
      #
      # Holds resolvers, footnote content, image references, and the
      # rule registry. Passed to every rule's #apply method so rules
      # can delegate sub-transforms (e.g., transform runs inside a
      # paragraph).
      class Context
        attr_reader :style_resolver, :numbering_resolver,
                    :footnotes, :image_refs, :registry

        # @param styles_configuration [Object, nil] Uniword styles config
        # @param numbering_configuration [Object, nil] Uniword numbering config
        # @param footnotes [Hash{String => Array}] footnote id → content paragraphs
        # @param registry [RuleRegistry] rule dispatch registry
        def initialize(styles_configuration: nil, numbering_configuration: nil,
                       footnotes: {}, registry: nil)
          @style_resolver = StyleResolver.new(styles_configuration)
          @numbering_resolver = NumberingResolver.new(numbering_configuration)
          @footnotes = footnotes
          @image_refs = []
          @registry = registry
        end

        # Transform an element using the registry
        #
        # @param element [Object] OOXML element
        # @return [Coradoc::CoreModel::Base, Array, String, nil]
        def transform(element)
          return nil if element.nil?

          rule = @registry.find_rule(element)
          rule.apply(element, self)
        end

        # Fetch footnote content by ID
        #
        # @param id [String, Integer] footnote ID
        # @return [String, nil] footnote text content
        def footnote_content(id)
          return nil unless id

          paragraphs = @footnotes[id.to_s]
          return nil unless paragraphs

          paragraphs.map do |para|
            extract_paragraph_text(para)
          end.join("\n")
        end

        # Record an image reference for later extraction
        #
        # @param ref [Hash] image reference with :src, :alt, etc.
        def register_image(ref)
          @image_refs << ref
        end

        private

        def extract_paragraph_text(paragraph)
          return '' unless paragraph.respond_to?(:text)

          paragraph.text.to_s
        end
      end
    end
  end
end
