# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Typed options for an include directive, parsed once at construction.
    #
    # Each asciidoctor selector (tags / lines / leveloffset / indent /
    # encoding) gets one typed attribute. Selectors downstream operate on
    # the typed form, never re-parsing the raw string (DRY).
    #
    #   tags          Array<String>   ["body"], [] when unspecified
    #   tags_wildcard Boolean         true for tags=*
    #   tags_inverted Boolean         true for tags=**
    #   lines_spec    String?         raw "1..2;5;7..8" — parsed by Lines selector
    #   leveloffset   IncludeLevelOffset?
    #   indent        Integer?        0 = strip, N = re-indent, nil = passthrough
    #   file_encoding String?         passed through to resolver for File.read
    class IncludeOptions < Base
      attribute :tags, :string, collection: true, default: -> { [] }
      attribute :tags_wildcard, :boolean, default: -> { false }
      attribute :tags_inverted, :boolean, default: -> { false }
      attribute :lines_spec, :string
      attribute :leveloffset, Coradoc::CoreModel::IncludeLevelOffset
      attribute :indent, :integer
      attribute :file_encoding, :string

      # Whether the lines selector is in effect. Tags are ignored when
      # lines is set — matches asciidoctor precedence (SPEC 3.5).
      def lines?
        !lines_spec.nil? && !lines_spec.strip.empty?
      end

      # Whether any tag selector is in effect.
      def tags?
        tags_wildcard || tags_inverted || !tags.empty?
      end

      # True when both selectors were specified (lines wins).
      def conflict_resolved_to_lines?
        lines? && tags?
      end

      # Build from a flat hash of asciidoctor-style key/value strings.
      # Whitespace around keys and values is trimmed (SPEC 6.3).
      #
      # @param attrs [Hash{String=>String}] e.g. {"tags"=>"a;b", "leveloffset"=>"+2"}
      # @return [IncludeOptions]
      def self.from_hash(attrs)
        new(build_args(attrs))
      end

      class << self
        private

        def build_args(attrs)
          cleaned = clean_keys(attrs)
          {
            tags: parse_tags(cleaned['tags']),
            tags_wildcard: wildcard?(cleaned['tags']),
            tags_inverted: inverted?(cleaned['tags']),
            lines_spec: cleaned['lines'],
            leveloffset: CoreModel::IncludeLevelOffset.parse(cleaned['leveloffset']),
            indent: parse_integer(cleaned['indent']),
            file_encoding: cleaned['encoding']
          }
        end

        def clean_keys(attrs)
          attrs.each_with_object({}) do |(k, v), h|
            h[k.to_s.strip] = v.to_s.strip
          end
        end

        def parse_tags(raw)
          return [] if raw.nil?
          trimmed = raw.strip
          return [] if trimmed.empty? || trimmed == '*' || trimmed == '**'

          trimmed.split(';').map(&:strip).reject(&:empty?)
        end

        def wildcard?(raw)
          !raw.nil? && raw.strip == '*'
        end

        def inverted?(raw)
          !raw.nil? && raw.strip == '**'
        end

        def parse_integer(raw)
          return nil if raw.nil? || raw.strip.empty?

          Integer(raw.strip)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
