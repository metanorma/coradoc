# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class DefinitionItemDrop < Base
        def term
          Escape.escape_html(stripped_term)
        end

        # All terms on this `<dt>`, escaped and id-stripped. Multi-term
        # `<dt>`'s (AsciiDoc `term1::\nterm2::`) carry multiple entries;
        # templates iterate this collection to emit one `<dt>` per term.
        # Falls back to `[term]` for legacy callers that only set the
        # singular `term` accessor.
        def terms
          raw = @model.terms
          collection = raw.nil? || raw.empty? ? [@model.term.to_s] : raw.map(&:to_s)
          collection.map { |t| Escape.escape_html(strip_term_id(t)) }
        end

        def term_id
          match = term_text.match(/\A\[\[([^\]]+)\]\]/)
          match&.[](1)
        end

        def definitions
          return [] unless @model.definitions

          @model.definitions.map { |d| content_to_liquid(d) }
        end

        def nested
          nested_model = @model.nested
          return nil unless nested_model.is_a?(CoreModel::DefinitionList) &&
                            nested_model.items&.any?

          DropFactory.create(nested_model)
        end

        private

        def term_text
          @term_text ||= @model.term.to_s
        end

        def stripped_term
          term_text.sub(/\A\[\[[^\]]+\]\]/, '')
        end

        # Strip a leading `[[id]]` anchor from a term string. Shared by
        # `terms` (per-entry) and `stripped_term` (primary term).
        def strip_term_id(text)
          text.to_s.sub(/\A\[\[[^\]]+\]\]/, '')
        end
      end

      DropFactory.register(CoreModel::DefinitionItem, DefinitionItemDrop)
    end
  end
end
