# frozen_string_literal: true

# Frozen copies of the hand-written rules retired by the #309 templates,
# kept as the oracle for old-vs-template parity specs.
module LegacyLint
  # ADOC001 — heading levels must not skip: a section may be at
  # most one level deeper than its parent. Skipped levels produce
  # broken document outlines.
  class AdocHeadingLevels < Coradoc::Lint::Rule
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

  # ADOC005 — section ids must be unique: duplicated anchors
  # break cross-references.
  class AdocDuplicateIds < Coradoc::Lint::Rule
    rule_id 'ADOC005'
    applies_to :asciidoc

    def check(document, path)
      ids = Hash.new(0)
      collect(document, ids)
      ids.select { |_id, count| count > 1 }
         .map do |id, count|
           build_violation(path: path,
                           message: "duplicate section id #{id.inspect} used #{count} times")
         end
    end

    private

    def collect(node, ids)
      Array(node.sections).each do |child|
        case child
        when Coradoc::AsciiDoc::Model::Section
          ids[child.id] += 1 if child.id
          collect(child, ids)
        end
      end
    end
  end
end
