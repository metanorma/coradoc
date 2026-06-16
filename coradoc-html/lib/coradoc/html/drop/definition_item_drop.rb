# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class DefinitionItemDrop < Base
        def term
          Escape.escape_html(stripped_term)
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
      end

      DropFactory.register(CoreModel::DefinitionItem, DefinitionItemDrop)
    end
  end
end
