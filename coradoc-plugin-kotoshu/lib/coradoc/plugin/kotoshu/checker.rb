# frozen_string_literal: true

require 'kotoshu'

module Coradoc
  module Plugin
    module Kotoshu
      # Orchestrates the spell check of one AsciiDoc document.
      #
      # Flow:
      #   1. Parse the source with Coradoc into a CoreModel tree.
      #   2. Walk the tree via {TextExtractor}, yielding prose spans.
      #   3. For each span, tokenize and ask the injected Kotoshu spellchecker
      #      whether each token is correct; collect misspellings + suggestions.
      #   4. Emit a {Report} with one {ReportError} per misspelled occurrence.
      #
      # The spellchecker is injected — the plugin does not know whether the
      # caller is using Kotoshu.spellchecker_for(language), a custom
      # Kotoshu::Spellchecker with a plain-text dictionary, or anything else.
      # It only requires that the object responds to #check_word (returning a
      # Kotoshu WordResult) and #tokenize (returning [[word, position], ...]).
      class Checker
        DEFAULT_TOKEN_PATTERN = /[A-Za-z][A-Za-z'\-]+/

        attr_reader :spellchecker, :language

        def initialize(spellchecker: nil, language: nil, token_pattern: DEFAULT_TOKEN_PATTERN)
          raise ArgumentError, 'Provide either spellchecker: or language:' if spellchecker.nil? && language.nil?

          @spellchecker = spellchecker || ::Kotoshu.spellchecker_for(language)
          @language = language
          @token_pattern = token_pattern
        end

        # Check an AsciiDoc document.
        #
        # @param adoc_text [String] the AsciiDoc source
        # @param document [String, nil] path or label for the document, used
        #   in the report header
        # @param generated_at [Time, String, nil] timestamp; defaults to now
        # @return [Report]
        def check(adoc_text, document: nil, generated_at: nil)
          doc = Coradoc.parse(adoc_text, format: :asciidoc)
          spans = TextExtractor.extract(doc, source: adoc_text)
          errors = []
          word_count = 0

          spans.each do |span|
            tokens = tokenize(span.text)
            word_count += tokens.size
            tokens.each do |word, position_in_span|
              result = spellchecker.check_word(word)
              next if result.correct?

              errors << build_error(span, word, position_in_span, result)
            end
          end

          Report.new(
            document: document,
            language: language || configured_language,
            generated_at: timestamp_for(generated_at),
            checker_version: VERSION,
            word_count: word_count,
            errors: errors
          )
        end

        # Check a file by path.
        #
        # @param path [String] file path
        # @param generated_at [Time, String, nil]
        # @return [Report]
        def check_file(path, generated_at: nil)
          source = File.read(path)
          check(source, document: path, generated_at: generated_at)
        end

        private

        def tokenize(text)
          tokens = []
          text.to_s.scan(@token_pattern).each_with_index do |match, _idx|
            offset = Regexp.last_match&.offset(0)&.first || 0
            tokens << [match, offset]
          end
          tokens
        end

        def build_error(span, word, position_in_span, result)
          context_text = build_context(span.text, position_in_span, word)
          suggestions = extract_suggestion_words(result)

          ReportError.new(
            word: word,
            context: context_text,
            element: span.element,
            section: span.section,
            line: span.line_hint,
            suggestions: suggestions
          )
        end

        def extract_suggestion_words(result)
          suggestions = result.suggestions
          return [] unless suggestions

          case suggestions
          when ::Kotoshu::Suggestions::SuggestionSet then suggestions.map { |s| suggestion_word(s) }
          when Array then suggestions.map { |s| suggestion_word(s) }
          else []
          end
        end

        def suggestion_word(suggestion)
          case suggestion
          when ::Kotoshu::Suggestions::Suggestion then suggestion.word
          else suggestion.to_s
          end
        end

        def build_context(span_text, position_in_span, word)
          radius = 40
          start_pos = [position_in_span - radius, 0].max
          end_pos = [position_in_span + word.length + radius, span_text.length].min
          snippet = span_text[start_pos..end_pos].to_s.strip
          prefix = start_pos.positive? ? '...' : ''
          suffix = end_pos < span_text.length ? '...' : ''
          "#{prefix}#{snippet}#{suffix}"
        end

        def configured_language
          return language if language
          return nil unless spellchecker.is_a?(::Kotoshu::Spellchecker)

          config = spellchecker.config
          return nil unless config.is_a?(::Kotoshu::Configuration)

          config.language
        end

        def timestamp_for(value)
          case value
          when nil then Time.now.utc.iso8601
          when Time then value.utc.iso8601
          else value.to_s
          end
        end
      end
    end
  end
end
