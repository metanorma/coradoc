# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Lint
      # ADOC002 — a document should have exactly one title: the
      # level-0 `=` heading carried by the document header.
      class DocumentTitle < Coradoc::Lint::Rule
        rule_id 'ADOC002'
        applies_to :asciidoc

        def check(document, path)
          title = document.header&.title
          text = case title
                 when Coradoc::AsciiDoc::Model::Title then title.content
                 when String then title
                 end
          return [] if text && !text.strip.empty?

          [build_violation(path: path,
                           message: 'document has no level-0 title (= ...)')]
        end
      end
    end
  end
end
