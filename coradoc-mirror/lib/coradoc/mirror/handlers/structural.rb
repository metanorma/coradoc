# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Structural
        # Top-level document handler. Stays flat; structural partitioning
        # (preface/sections/bibliography) is opted into via the
        # partition_structural: kwarg on CoreModelToMirror#call, which
        # delegates to Mirror::Partitioner.
        def self.document(element, context:)
          content = context.extract_content(element)
          Node::Document.new(
            attrs: Node::Document::Attrs.new(title: element.title, id: element.id),
            content: content
          )
        end

        # Map CoreModel section style/title hints to JS SECTION_TYPES.
        # When coradoc propagates AsciiDoc style attributes ([appendix],
        # [bibliography], etc.) into SectionElement.attributes, this table
        # is used to pick the right JS section type. Default fallback is
        # `clause` (the JS generic section type).
        SECTION_STYLE_TO_JS_TYPE = {
          'appendix' => 'annex',
          'annex' => 'annex',
          'bibliography' => 'references',
          'references' => 'references',
          'abstract' => 'abstract',
          'foreword' => 'foreword',
          'introduction' => 'introduction',
          'acknowledgements' => 'acknowledgements',
          'terms' => 'terms',
          'definitions' => 'definitions'
        }.freeze

        def self.section(element, context:)
          content = context.extract_content(element)
          type = context.partition_structural ? section_type_for(element) : 'section'

          Node::Section.new(
            type: type,
            attrs: Node::Section::Attrs.new(
              id: element.id,
              title: element.title,
              level: element.heading_level
            ),
            content: content
          )
        end

        def self.section_type_for(element)
          style = section_style(element)
          SECTION_STYLE_TO_JS_TYPE[style] || 'clause'
        end

        # Reads `style` then `role` from SectionElement#attributes via the
        # Metadata#[] accessor — no intermediate hash allocation per call.
        def self.section_style(element)
          attrs = element.attributes
          return nil unless attrs.is_a?(Coradoc::CoreModel::Metadata)

          attrs['style'] || attrs['role']
        end

        def self.preamble(element, context:)
          content = context.extract_content(element)
          Node::Preamble.new(content: content)
        end

        def self.header(element, context:)
          content = context.extract_content(element)
          Node::Header.new(
            attrs: Node::Header::Attrs.new(
              title: element.title,
              level: element.heading_level
            ),
            content: content
          )
        end
      end
    end
  end
end
