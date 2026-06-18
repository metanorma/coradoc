# frozen_string_literal: true

module Coradoc
  module Markdown
    # DefinitionTerm model representing a term in a definition list.
    #
    # A term can have multiple definitions and can span multiple lines.
    # Terms can also have IAL attributes attached.
    #
    # A term can carry a nested DefinitionList when the original document
    # had structured sub-entries (e.g. glossary sub-terms). When `nested`
    # is present, the serializer's nested_html strategy kicks in to emit
    # HTML `<dl>` structure that Markdown syntax cannot express.
    class DefinitionTerm < Base
      attribute :text, :string
      attribute :definitions, Coradoc::Markdown::DefinitionItem, collection: true, default: []

      # Optional nested definition list under this term.
      # When present, the flat-PHP-Markdown-Extra syntax is no longer
      # sufficient and the serializer falls back to HTML <dl>/<dt>/<dd>.
      attribute :nested, Coradoc::Markdown::DefinitionList

      def initialize(text: '', definitions: [], nested: nil, **rest)
        super
        @text = text
        @definitions = definitions
        @nested = nested
      end
    end
  end
end
