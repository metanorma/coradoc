# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Lint
      # ADOC005 — section ids must be unique: duplicated anchors
      # break cross-references.
      class DuplicateIds < Coradoc::Lint::Rule
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
  end
end
