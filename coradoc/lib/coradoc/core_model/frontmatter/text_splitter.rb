# frozen_string_literal: true

module Coradoc
  module CoreModel
    class FrontmatterBlock
      # Format-agnostic text splitter for the YAML frontmatter block
      # convention (`---\n...\n---\n` at the very start of a document).
      #
      # Lives under FrontmatterBlock alongside Codec, SchemaResolver,
      # and FieldTransform — together they form the complete frontmatter
      # machinery (MECE):
      #
      #   TextSplitter   — text → (frontmatter_text, body_text)
      #   Codec          — frontmatter_text ↔ typed FrontmatterBlock
      #   SchemaResolver — typed FrontmatterBlock → validation errors
      #   FieldTransform — typed FrontmatterBlock → transformed block
      #
      # Format gems (Markdown, AsciiDoc, ...) call this splitter at the
      # top of their parse pipeline so frontmatter never reaches the
      # format's block parser. Single source of truth (DRY).
      module TextSplitter
        OPEN_DELIMITER = '---'
        CLOSE_DELIMITERS = %w[--- ...].freeze

        # Result of splitting source text. +frontmatter+ is the raw YAML
        # body (without delimiters), nil if no frontmatter was present.
        # +body+ is the remaining document text.
        Result = Struct.new(:frontmatter, :body, keyword_init: true) do
          def frontmatter?
            !frontmatter.nil? && !frontmatter.empty?
          end
        end

        class << self
          # @param text [String, nil] Source document text.
          # @return [Result]
          def call(text)
            return Result.new(frontmatter: nil, body: '') if text.nil? || text.empty?

            lines = text.lines
            return empty_with(text) unless opens_frontmatter?(lines.first)

            close_index = find_close_line(lines, 1)
            return empty_with(text) if close_index.nil?

            frontmatter = lines[1...close_index].join
            body = lines[(close_index + 1)..].join
            body = body.sub(/\A\n+/, '') if body.start_with?("\n")

            Result.new(frontmatter: frontmatter, body: body)
          end

          private

          def opens_frontmatter?(first_line)
            return false unless first_line

            first_line.strip == OPEN_DELIMITER
          end

          def find_close_line(lines, start_at)
            start_at.upto(lines.size - 1) do |i|
              return i if CLOSE_DELIMITERS.include?(lines[i].strip)
            end
            nil
          end

          def empty_with(text)
            Result.new(frontmatter: nil, body: text)
          end
        end
      end
    end
  end
end
