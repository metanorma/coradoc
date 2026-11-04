# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Lint
      # AsciiDoc bindings for the shared invariant templates (#309).
      # Every AsciiDoc model path the templates touch lives in this
      # file (and only here), so a model move (#306) updates one place.
      module Registrations
        SECTION = Coradoc::AsciiDoc::Model::Section

        module_function

        def sections(node)
          Array(node.sections).grep(SECTION)
        end

        def level(section)
          section.title&.level_int
        end

        def title_text(section)
          title = section.title
          title.respond_to?(:content) ? title.content : title.to_s
        end

        def section_id(section)
          section.id
        end

        # ADOC001 — a section may be at most one level deeper than
        # its parent.
        HEADING_LEVELS = Coradoc::Lint::Template.bind(
          :monotonic, id: 'ADOC001', format: :asciidoc,
                      roots: method(:sections).to_proc,
                      children: method(:sections).to_proc,
                      level: method(:level).to_proc,
                      label: method(:title_text).to_proc
        )

        # ADOC005 — section ids must be unique.
        DUPLICATE_IDS = Coradoc::Lint::Template.bind(
          :unique, id: 'ADOC005', format: :asciidoc,
                   roots: method(:sections).to_proc,
                   children: method(:sections).to_proc,
                   key: method(:section_id).to_proc,
                   message: lambda { |id, count|
                     "duplicate section id #{id.inspect} used #{count} times"
                   }
        )

        RULES = [HEADING_LEVELS, DUPLICATE_IDS].freeze
      end
    end
  end
end
