# frozen_string_literal: true

require 'set'

module Coradoc
  module Mirror
    module Handlers
      module Structural
        # Top-level document handler. Stays flat; structural partitioning
        # (preface/sections/bibliography) is opted into via the
        # partition_structural: kwarg on CoreModelToMirror#call, which calls
        # the partition_doc_children helper below.
        def self.document(element, context:)
          content = context.extract_content(element)
          Node::Document.new(
            title: element.title,
            id: element.id,
            content: content
          )
        end

        # JS SECTION_TYPES that count as "section" for partitioning.
        JS_SECTION_TYPES = Set.new(%w[
          clause annex content_section abstract foreword introduction
          acknowledgements terms definitions references section
        ]).freeze

        # Returns a hash with arrays under :preface, :sections, :bibliography,
        # :trailing. Iteration is single-pass with a state machine: loose
        # blocks before any section go into :preface; once a section appears,
        # loose blocks go into :sections (preserving document order); once a
        # bibliography appears, loose blocks go into :trailing. Footnotes
        # blocks always go into :trailing.
        def self.partition_doc_children(children)
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
              if JS_SECTION_TYPES.include?(child.type)
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
            id: element.id,
            title: element.title,
            level: element.heading_level,
            content: content
          )
        end

        def self.section_type_for(element)
          style = section_style(element)
          SECTION_STYLE_TO_JS_TYPE[style] || 'clause'
        end

        def self.section_style(element)
          attrs = element.attributes
          return nil unless attrs.is_a?(Coradoc::CoreModel::Metadata)

          attrs.to_h['style'] || attrs.to_h['role']
        end

        def self.preamble(element, context:)
          content = context.extract_content(element)
          Node::Preamble.new(content: content)
        end

        def self.header(element, context:)
          content = context.extract_content(element)
          Node::Header.new(
            title: element.title,
            level: element.heading_level,
            content: content
          )
        end
      end
    end
  end
end
