# frozen_string_literal: true

require 'lutaml/model'

module Coradoc
  module Plugin
    module Kotoshu
      # One misspelling in a {Report}.
      #
      # Mirrors what a Word-style spell-check report exposes per error:
      #   - the misspelled word
      #   - a snippet of surrounding text (so a reviewer can locate it)
      #   - the element kind and section that contained it
      #   - a best-effort 1-based source line
      #   - the suggestions Kotoshu produced, with distance and confidence
      class ReportError < Lutaml::Model::Serializable
        attribute :word, :string
        attribute :context, :string
        attribute :element, :string
        attribute :section, :string
        attribute :line, :integer
        attribute :column, :integer
        attribute :suggestions, :string, collection: true

        def initialize(word:, context: nil, element: nil, section: nil,
                       line: nil, column: nil, suggestions: [])
          super
        end

        def has_suggestions?
          suggestions && !suggestions.empty?
        end

        def to_s
          "#{word} (line #{line || '?'})"
        end
      end
    end
  end
end
