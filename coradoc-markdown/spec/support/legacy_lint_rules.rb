# frozen_string_literal: true

# Frozen copies of the hand-written rules retired by the #309 templates,
# kept as the oracle for old-vs-template parity specs.
module LegacyLint
  # MD001 — heading levels must not skip: a heading may be at most
  # one level deeper than the previous heading (markdownlint MD001).
  # Headings are top-level blocks in the Markdown model.
  class MdHeadingLevels < Coradoc::Lint::Rule
    rule_id 'MD001'
    applies_to :markdown

    def check(document, path)
      headings = Array(document.blocks).filter_map do |block|
        [block.level, block.text] if block.is_a?(Coradoc::Markdown::Heading)
      end
      headings.each_cons(2).filter_map do |(prev, _), (level, text)|
        next unless level > prev + 1

        build_violation(path: path,
                        message: "heading level skips from #{prev} to #{level}: #{text}")
      end
    end
  end

  # MD024 — headings at the same level must have unique text.
  # Duplicate headings produce ambiguous outlines.
  class MdDuplicateHeadings < Coradoc::Lint::Rule
    rule_id 'MD024'
    applies_to :markdown

    def check(document, path)
      seen = Hash.new(0)
      Array(document.blocks).each do |block|
        next unless block.is_a?(Coradoc::Markdown::Heading)

        seen[[block.level, block.text]] += 1
      end
      seen.select { |_key, count| count > 1 }
          .map do |(level, text), count|
            build_violation(
              path: path,
              message: "duplicate heading (level #{level}): #{text.inspect} used #{count} times"
            )
          end
    end
  end
end
