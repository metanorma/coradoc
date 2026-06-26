# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      # All JS SECTION_TYPES reverse to a generic SectionElement. Style
      # information lives in the original AsciiDoc and is preserved only
      # on the forward side; the reverse side collapses them.
      class Section < Base
        registers 'section', 'clause', 'annex', 'content_section',
                  'abstract', 'foreword', 'introduction',
                  'acknowledgements', 'terms', 'definitions', 'references'

        def build(node)
          attrs = node.attrs
          CoreModel::SectionElement.new(
            title: attrs&.title,
            level: attrs&.level,
            id: attrs&.id,
            children: build_content(node)
          )
        end
      end
    end
  end
end
