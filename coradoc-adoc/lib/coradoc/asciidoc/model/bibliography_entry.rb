# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Individual bibliography entry for AsciiDoc documents.
      #
      # Bibliography entries represent single references within a bibliography,
      # with anchor names for citation linking.
      #
      # @!attribute [r] anchor_name
      #   @return [String, nil] The anchor name for citing this entry
      #
      # @!attribute [r] document_id
      #   @return [String, nil] The document identifier
      #
      # @!attribute [r] ref_text
      #   @return [String, nil] The reference text/citation
      #
      # @!attribute [r] line_break
      #   @return [String] Line break character (default: "")
      #
      # @example Create a bibliography entry
      #   entry = Coradoc::AsciiDoc::Model::BibliographyEntry.new
      #   entry.anchor_name = "smith2023"
      #   entry.ref_text = "Smith, J. (2023). Example citation."
      #
      # @see Coradoc::AsciiDoc::Model::Bibliography Bibliography container
      #
      class BibliographyEntry < Base
        attribute :anchor_name, :string
        attribute :document_id, :string
        attribute :ref_text, :string
        attribute :line_break, :string, default: -> { '' }

        # Coerce a raw parser AST value into the canonical ref_text string.
        # Accepts the shapes produced by Parser::Bibliography for `:ref_text`:
        # nil, Parslet::Slice, plain String, single Model::Base, or an Array
        # of any of these. Model objects (TextElement, Inline::Italic, etc.)
        # are flattened via TextExtractVisitor so their text content is
        # preserved instead of leaking `#<Class:0x...>` inspect strings.
        # Keeping this coercion on the model that owns ref_text (rather than
        # in a transformer rule) keeps the transformer declarative and lets
        # callers build entries from any source shape.
        # @param raw [Object, nil]
        # @return [String]
        def self.coerce_ref_text(raw)
          return '' if raw.nil?

          case raw
          when Array then raw.map { |e| coerce_ref_text(e) }.join
          when String then raw
          when Coradoc::AsciiDoc::Model::Base
            Coradoc::AsciiDoc::Transform::TextExtractVisitor.new.extract(raw).to_s
          else raw.to_s
          end
        end
      end
    end
  end
end
