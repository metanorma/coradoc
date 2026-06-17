# frozen_string_literal: true

module Coradoc
  module Markdown
    module Parser
      # Standalone frontmatter extractor for Markdown.
      #
      # Sole responsibility: detect and split the leading YAML
      # frontmatter block (`---\n...\n---\n`) from document text.
      # Does NOT parse or validate YAML itself — that is the job of
      # CoreModel::FrontmatterBlock::Codec (MECE: this layer handles
      # the Markdown delimiter convention, Codec handles YAML).
      #
      # Frontmatter is recognized iff the document starts with a line
      # that is exactly `---` (the YAML directive). The block ends at
      # the next line that is exactly `---` (or `...`). Body text
      # follows.
      module FrontmatterParser
        OPEN_DELIMITER = '---'
        CLOSE_DELIMITERS = %w[--- ...].freeze

        Result = Struct.new(:frontmatter, :body, keyword_init: true) do
          def frontmatter?
            !frontmatter.nil? && !frontmatter.empty?
          end
        end

        class << self
          # @param text [String, nil] Source Markdown text.
          # @return [Result] Struct with +frontmatter+ (raw YAML text,
          #   nil if absent) and +body+ (rest of document).
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

          # Walk lines after the opener to find the closing delimiter.
          # An empty line before a close is allowed (YAML permits it),
          # but the close must be the first non-content line.
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
