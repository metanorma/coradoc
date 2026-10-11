# frozen_string_literal: true

module Coradoc
  module Markdown
    module Lint
      # MD024 — headings at the same level must have unique text.
      # Duplicate headings produce ambiguous outlines.
      class DuplicateHeadings < Coradoc::Lint::Rule
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
  end
end
