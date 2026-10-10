# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Lint
      # ADOC001 — heading levels must not skip: a section may be at
      # most one level deeper than its parent. Skipped levels produce
      # broken document outlines.
      class HeadingLevels < Coradoc::Lint::Rule
        rule_id 'ADOC001'
        applies_to :asciidoc

        def check(document, path)
          violations = []
          sections(document).each { |s| walk(s, 0, path, violations) }
          violations
        end

        private

        def walk(section, parent_level, path, violations)
          level = section.title&.level_int
          if level && level > parent_level + 1
            violations << build_violation(
              path: path,
              message: "heading level skips from #{parent_level} to #{level}: " \
                       "#{title_text(section)}"
            )
          end
          sections(section).each { |child| walk(child, level || parent_level, path, violations) }
        end

        def sections(node)
          Array(node.sections).grep(Coradoc::AsciiDoc::Model::Section)
        end

        def title_text(section)
          title = section.title
          title.respond_to?(:content) ? title.content : title.to_s
        end
      end
    end
  end
end
