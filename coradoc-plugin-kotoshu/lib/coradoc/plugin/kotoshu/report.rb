# frozen_string_literal: true

require 'lutaml/model'
require 'json'

module Coradoc
  module Plugin
    module Kotoshu
      # The full spell-check report for one document.
      #
      # Word-style report: a header (document path, language, generation
      # timestamp, summary counts) followed by an ordered list of {ReportError}
      # entries — one per misspelled occurrence.
      #
      # Serialization is provided by lutaml-model: {#to_yaml}, {#to_json},
      # {.from_yaml}, {.from_json} are all framework-supplied and reflect the
      # declared attributes + mappings.
      class Report < Lutaml::Model::Serializable
        attribute :document, :string
        attribute :language, :string
        attribute :generated_at, :string
        attribute :checker_version, :string
        attribute :word_count, :integer, default: 0
        attribute :error_count, :integer, default: 0
        attribute :unique_error_count, :integer, default: 0
        attribute :errors, ReportError, collection: true

        mappings do
          root 'kotoshu_report'
          map :document, to: :document
          map :language, to: :language
          map :generated_at, to: :generated_at
          map :checker_version, to: :checker_version
          map :word_count, to: :word_count
          map :error_count, to: :error_count
          map :unique_error_count, to: :unique_error_count
          map :errors, to: :errors
        end

        def initialize(document: nil, language: nil, generated_at: nil,
                       checker_version: nil, word_count: 0, errors: [])
          unique = errors.map(&:word).uniq.size
          super(
            document: document,
            language: language,
            generated_at: generated_at,
            checker_version: checker_version,
            word_count: word_count,
            error_count: errors.size,
            unique_error_count: unique,
            errors: errors
          )
        end

        def clean?
          errors.empty?
        end

        def misspelled_words
          errors.map(&:word)
        end

        def unique_misspelled_words
          errors.map(&:word).uniq
        end

        def errors_for(word)
          errors.select { |e| e.word == word }
        end

        def each_error(&)
          errors.each(&)
        end

        def to_s
          "#{document || '(inline)'}: #{error_count} error(s) across " \
            "#{unique_error_count} unique word(s)"
        end
      end
    end
  end
end
