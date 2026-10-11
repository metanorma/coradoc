# frozen_string_literal: true

module Coradoc
  module Html
    module Lint
      # HTML001 — heading levels must not skip: a heading may be at
      # most one level deeper than the previous heading. Skipped
      # levels produce broken AsciiDoc section outlines on conversion.
      class HeadingLevels < Coradoc::Lint::Rule
        rule_id 'HTML001'
        applies_to :html

        def check(document, path)
          headings = Array(document).select do |element|
            element.is_a?(CoreModel::SectionElement)
          end
          violations = []
          headings.each_cons(2) do |prev, heading|
            next unless heading.level > prev.level + 1

            violations << build_violation(
              path: path,
              message: "heading level skips from #{prev.level} to " \
                       "#{heading.level}: #{heading.title}"
            )
          end
          violations
        end
      end
    end
  end
end
