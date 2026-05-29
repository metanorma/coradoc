# frozen_string_literal: true

require_relative 'base'

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

        private

        def term_text
          @term_text ||= @model.term.to_s
        end

        def stripped_term
          term_text.sub(/\A\[\[[^\]]+\]\]/, '')
        end
      end
    end
  end
end
