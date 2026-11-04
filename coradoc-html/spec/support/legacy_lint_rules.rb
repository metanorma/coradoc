# frozen_string_literal: true

# Frozen copies of the hand-written rules retired by the #309 templates,
# kept as the oracle for old-vs-template parity specs.
module LegacyLint
  # HTML001 — heading levels must not skip: a heading may be at
  # most one level deeper than the previous heading. Skipped
  # levels produce broken AsciiDoc section outlines on conversion.
  class HtmlHeadingLevels < Coradoc::Lint::Rule
    rule_id 'HTML001'
    applies_to :html

    def check(document, path)
      headings = Array(document).select do |element|
        element.is_a?(Coradoc::CoreModel::SectionElement)
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

  # HTML002 — images must carry alt text: images without alt
  # convert to AsciiDoc images with no accessible description.
  class HtmlImageAlt < Coradoc::Lint::Rule
    rule_id 'HTML002'
    applies_to :html

    def check(document, path)
      Array(document).filter_map do |element|
        next unless element.is_a?(Coradoc::CoreModel::Image)
        next if element.alt && !element.alt.strip.empty?

        build_violation(path: path,
                        message: "image without alt text: #{element.src}")
      end
    end
  end
end
