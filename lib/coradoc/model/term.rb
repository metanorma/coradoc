# frozen_string_literal: true

module Coradoc
  module Model
    class Term < Base
      attribute :term, :string
      attribute :type, :string
      attribute :lang, :string, default: -> { "en" }
      attribute :line_break, :string, default: -> { "" }

      asciidoc do
        map_attribute "term", to: :term
        map_attribute "type", to: :type
        map_attribute "lang", to: :lang
      end

      def validate
        errors = super

        if term.nil? || term.empty?
          errors << Lutaml::Model::Error.new("Term cannot be nil or empty")
        end

        if type.nil? || type.empty?
          errors << Lutaml::Model::Error.new("Type cannot be nil or empty")
        end

        errors
      end

      def to_asciidoc
        return "#{type}:[#{term}]#{line_break}" if lang.to_s == "en"

        "[#{type}]##{term}##{line_break}"
      end
    end
  end
end
