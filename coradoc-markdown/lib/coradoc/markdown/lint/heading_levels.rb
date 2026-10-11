# frozen_string_literal: true

module Coradoc
  module Markdown
    module Lint
      # MD001 — heading levels must not skip: a heading may be at most
      # one level deeper than the previous heading (markdownlint MD001).
      # Headings are top-level blocks in the Markdown model.
      class HeadingLevels < Coradoc::Lint::Rule
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
    end
  end
end
