# frozen_string_literal: true

module Coradoc
  module Html
    # HTML entity handling
    module Entity
      # Named HTML entities
      NAMED_ENTITIES = {
        'nbsp' => "\u00A0",
        'lt' => '<',
        'gt' => '>',
        'amp' => '&',
        'quot' => '"',
        'apos' => "'",
        'cent' => "\u00A2",
        'pound' => "\u00A3",
        'yen' => "\u00A5",
        'euro' => "\u20AC",
        'copy' => "\u00A9",
        'reg' => "\u00AE",
        'trade' => "\u2122",
        'mdash' => "\u2014",
        'ndash' => "\u2013",
        'hellip' => "\u2026",
        'laquo' => "\u00AB",
        'raquo' => "\u00BB",
        'ldquo' => "\u201C",
        'rdquo' => "\u201D",
        'lsquo' => "\u2018",
        'rsquo' => "\u2019"
      }.freeze

      class << self
        # Encode text to HTML entities
        def encode(text, options = {})
          return '' if text.nil?
          return text unless text.is_a?(String)

          encoded = text.dup

          # Basic HTML entities
          encoded = encoded
                    .gsub('&', '&amp;')
                    .gsub('<', '&lt;')
                    .gsub('>', '&gt;')
                    .gsub('"', '&quot;')

          # Optionally encode additional characters
          encoded = encoded.gsub("'", '&#39;') if options[:encode_quotes]

          encoded = encoded.gsub("\u00A0", '&nbsp;') if options[:encode_nbsp]

          encoded
        end

        # Decode HTML entities to text
        def decode(text)
          return '' if text.nil?
          return text unless text.is_a?(String)

          decoded = text.dup

          # Decode named entities
          NAMED_ENTITIES.each do |name, char|
            decoded = decoded.gsub("&#{name};", char)
          end

          # Decode numeric entities (decimal)
          decoded = decoded.gsub(/&#(\d+);/) do
            [::Regexp.last_match(1).to_i].pack('U')
          end

          # Decode numeric entities (hexadecimal)
          decoded = decoded.gsub(/&#x([0-9a-fA-F]+);/) do
            [::Regexp.last_match(1).to_i(16)].pack('U')
          end

          # Decode basic entities last
          decoded
            .gsub('&quot;', '"')
            .gsub('&#39;', "'")
            .gsub('&#x27;', "'")
            .gsub('&lt;', '<')
            .gsub('&gt;', '>')
            .gsub('&amp;', '&')
        end

        # Convert character to named entity if available
        def to_named_entity(char)
          entity_name = NAMED_ENTITIES.key(char)
          entity_name ? "&#{entity_name};" : char
        end

        # Convert character to numeric entity
        def to_numeric_entity(char, format: :decimal)
          codepoint = char.ord

          case format
          when :decimal
            "&##{codepoint};"
          when :hex, :hexadecimal
            "&#x#{codepoint.to_s(16)};"
          else
            char
          end
        end

        # Check if text contains HTML entities
        def has_entities?(text)
          return false unless text.is_a?(String)

          text.match?(/&[a-zA-Z]+;|&#\d+;|&#x[0-9a-fA-F]+;/)
        end

        # Normalize entities (convert all to named where possible, numeric otherwise)
        def normalize(text)
          return '' if text.nil?
          return text unless text.is_a?(String)

          # First decode to get actual characters
          decoded = decode(text)

          # Then encode back using named entities where possible
          decoded.chars.map do |char|
            case char
            when '&', '<', '>', '"', "'"
              encode(char)
            else
              named = to_named_entity(char)
              named == char ? char : named
            end
          end.join
        end
      end
    end
  end
end
