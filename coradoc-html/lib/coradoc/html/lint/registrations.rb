# frozen_string_literal: true

module Coradoc
  module Html
    module Lint
      # HTML bindings for the shared invariant templates (#309). The
      # parsed document is a CoreModel element array.
      module Registrations
        module_function

        def headings(document)
          Array(document).select { |e| e.is_a?(CoreModel::SectionElement) }
        end

        def images(document)
          Array(document).select { |e| e.is_a?(CoreModel::Image) }
        end

        # HTML001 — a heading may be at most one level deeper than the
        # previous heading.
        HEADING_LEVELS = Coradoc::Lint::Template.bind(
          :monotonic, id: 'HTML001', format: :html, order: :sequence,
                      roots: method(:headings).to_proc,
                      level: :level.to_proc,
                      label: :title.to_proc
        )

        # HTML002 — images must carry alt text.
        IMAGE_ALT = Coradoc::Lint::Template.bind(
          :present, id: 'HTML002', format: :html,
                    subjects: method(:images).to_proc,
                    present: ->(image) { image.alt && !image.alt.strip.empty? },
                    message: ->(image) { "image without alt text: #{image.src}" }
        )

        RULES = [HEADING_LEVELS, IMAGE_ALT].freeze
      end
    end
  end
end
