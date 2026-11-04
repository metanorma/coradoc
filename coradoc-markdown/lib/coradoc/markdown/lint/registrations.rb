# frozen_string_literal: true

module Coradoc
  module Markdown
    module Lint
      # Markdown bindings for the shared invariant templates (#309).
      # Headings are top-level blocks in the Markdown model.
      module Registrations
        module_function

        def headings(document)
          Array(document.blocks).grep(Coradoc::Markdown::Heading)
        end

        # MD001 — a heading may be at most one level deeper than the
        # previous heading (markdownlint MD001).
        HEADING_LEVELS = Coradoc::Lint::Template.bind(
          :monotonic, id: 'MD001', format: :markdown, order: :sequence,
                      roots: method(:headings).to_proc,
                      level: :level.to_proc,
                      label: :text.to_proc
        )

        # MD024 — headings at the same level must have unique text.
        DUPLICATE_HEADINGS = Coradoc::Lint::Template.bind(
          :unique, id: 'MD024', format: :markdown,
                   roots: method(:headings).to_proc,
                   key: ->(heading) { [heading.level, heading.text] },
                   message: lambda { |(level, text), count|
                     "duplicate heading (level #{level}): #{text.inspect} used #{count} times"
                   }
        )

        RULES = [HEADING_LEVELS, DUPLICATE_HEADINGS].freeze
      end
    end
  end
end
