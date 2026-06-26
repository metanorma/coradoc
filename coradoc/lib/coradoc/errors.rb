# frozen_string_literal: true

module Coradoc
  # Base error class for all Coradoc errors
  class Error < StandardError; end

  # Suggestion patterns for common parsing errors
  #
  # These patterns are matched against error messages and source content
  # to provide helpful suggestions for fixing common issues.
  ERROR_SUGGESTIONS = [
    {
      pattern: /unterminated.*string|unexpected.*end.*of.*input|expected.*["']/i,
      suggestion: 'Check for unclosed quotes or strings',
      examples: ["'text'", '"text"']
    },
    {
      pattern: /unexpected.*indentation|indentation.*error|inconsistent.*indent/i,
      suggestion: 'Check indentation - use consistent spaces or tabs',
      examples: ['  indented line', '    nested item']
    },
    {
      pattern: /missing.*separator|expected.*delimiter|missing.*comma/i,
      suggestion: 'Add missing separator between elements',
      examples: ['item1, item2', 'key: value']
    },
    {
      pattern: /invalid.*attribute|unknown.*attribute|attribute.*not.*allowed/i,
      suggestion: 'Check attribute spelling and allowed values',
      examples: ['[role=example]', '[source,ruby]']
    },
    {
      pattern: /invalid.*heading|heading.*level|expected.*heading/i,
      suggestion: 'Use valid heading syntax with = or # markers',
      examples: ['= Level 1', '== Level 2', '### Level 3']
    },
    {
      pattern: /invalid.*list|list.*marker|expected.*list.*item/i,
      suggestion: 'Use correct list markers (*, -, ., or numbered)',
      examples: ['* bullet', '. ordered', 'term:: definition']
    },
    {
      pattern: /invalid.*link|malformed.*url|link.*syntax/i,
      suggestion: 'Use correct link syntax: text[url] or link:url[]',
      examples: ['Google[https://google.com]', 'link:file.adoc[]']
    },
    {
      pattern: /invalid.*table|table.*delimiter|expected.*separator/i,
      suggestion: 'Check table syntax with | delimiters',
      examples: ["|===\n| Cell 1 | Cell 2\n|==="]
    },
    {
      pattern: /invalid.*block|block.*delimiter|unterminated.*block/i,
      suggestion: 'Ensure block delimiters match (----, ****, ====, etc.)',
      examples: ["----\ncode\n----", "====\nexample\n===="]
    },
    {
      pattern: /invalid.*macro|unknown.*macro|macro.*syntax/i,
      suggestion: 'Check macro syntax: name:target[attributes]',
      examples: ['include::file.adoc[]', 'image::image.png[]']
    }
  ].freeze

  # Enhanced error classes with source context support
  #
  # These error classes provide additional context such as line numbers,
  # column positions, source snippets, and suggestions to help users debug issues.
  #
  # @example Raising a parse error with context
  #   raise ParseError.new(
  #     "Unexpected token",
  #     source: content,
  #     line: 10,
  #     column: 5
  #   )
  #
  # @example Handling errors with context
  #   begin
  #     Coradoc.parse(text, format: :markdown)
  #   rescue Coradoc::ParseError => e
  #     puts e.message_with_context
  #     puts e.suggestion if e.suggestion
  #   end
  #
  class ParseError < Error
    attr_reader :source, :line, :column, :snippet_lines, :suggestion

    # Create a new parse error with optional source context
    #
    # @param message [String] The error message
    # @param source [String, nil] The source text being parsed
    # @param line [Integer, nil] The line number (1-indexed)
    # @param column [Integer, nil] The column number (1-indexed)
    # @param snippet_lines [Integer] Number of context lines to show (default: 3)
    # @param suggestion [String, nil] Optional suggestion for fixing the error
    def initialize(message, source: nil, line: nil, column: nil, snippet_lines: 3,
                   suggestion: nil)
      @source = source
      @line = line
      @column = column
      @snippet_lines = snippet_lines
      @suggestion = suggestion || find_suggestion(message, source, line)
      super(build_message(message))
    end

    # Returns the error message with full context
    #
    # @return [String] Formatted error message with source snippet
    def message_with_context
      return message unless source && line

      msg = message
      msg += "\n\n"
      msg += source_snippet
      if suggestion
        msg += "\n\n"
        msg += "Suggestion: #{suggestion}"
      end
      msg
    end

    # Returns the source snippet around the error location
    #
    # @return [String] Formatted source snippet with line numbers
    def source_snippet
      return '' unless source && line

      lines = source.lines
      start_line = [1, line - snippet_lines].max
      end_line = [lines.length, line + snippet_lines].min

      snippet = []
      (start_line..end_line).each do |i|
        prefix = i == line ? '>>> ' : '    '
        snippet_line = lines[i - 1]&.chomp || ''
        snippet << "#{prefix}#{i.to_s.rjust(4)}: #{snippet_line}"

        # Add column indicator on the error line
        if i == line && column
          indicator = "#{' ' * (prefix.length + 6 + column - 1)}^"
          snippet << indicator
        end
      end

      snippet.join("\n")
    end

    # Returns all suggestions that match this error
    #
    # @return [Array<String>] List of applicable suggestions
    def all_suggestions
      return [] unless message || source

      suggestions = []
      ERROR_SUGGESTIONS.each do |entry|
        suggestions << format_suggestion(entry) if entry[:pattern].match?(message)
      end

      # Also check source line if available
      if source && line
        source_line = source.lines[line - 1]
        if source_line
          ERROR_SUGGESTIONS.each do |entry|
            suggestions << format_suggestion(entry) if entry[:pattern].match?(source_line)
          end
        end
      end

      suggestions.uniq
    end

    private

    def build_message(message)
      context = []
      context << "line #{line}" if line
      context << "column #{column}" if column

      if context.any?
        "#{message} (at #{context.join(', ')})"
      else
        message
      end
    end

    def find_suggestion(message, source, line)
      return nil unless message || source

      # Check message against patterns
      ERROR_SUGGESTIONS.each do |entry|
        return format_suggestion(entry) if entry[:pattern].match?(message)
      end

      # Check source line if available
      if source && line
        source_line = source.lines[line - 1]
        if source_line
          ERROR_SUGGESTIONS.each do |entry|
            return format_suggestion(entry) if entry[:pattern].match?(source_line)
          end
        end
      end

      nil
    end

    def format_suggestion(entry)
      result = entry[:suggestion]
      result += " (e.g., #{entry[:examples].first(2).join(', ')})" if entry[:examples]&.any?
      result
    end
  end

  # Error raised when validation fails
  #
  # @example
  #   raise ValidationError.new(
  #     "Invalid document structure",
  #     errors: ["Missing title", "Empty section"]
  #   )
  #
  class ValidationError < Error
    attr_reader :errors

    # Create a new validation error
    #
    # @param message [String] The error message
    # @param errors [Array<String>] List of specific validation errors
    def initialize(message, errors: [])
      @errors = errors
      super(build_message(message))
    end

    private

    def build_message(message)
      return message if errors.empty?

      "#{message}\n  - #{errors.join("\n  - ")}"
    end
  end

  # Error raised when transformation fails
  #
  # @example
  #   raise TransformationError.new(
  #     "Cannot convert element",
  #     source_type: "Paragraph",
  #     target_type: "CoreModel::Block"
  #   )
  #
  class TransformationError < Error
    attr_reader :source_type, :target_type

    # Create a new transformation error
    #
    # @param message [String] The error message
    # @param source_type [String, Class, nil] The source type being transformed
    # @param target_type [String, Class, nil] The target type
    def initialize(message, source_type: nil, target_type: nil)
      @source_type = source_type
      @target_type = target_type
      super(build_message(message))
    end

    private

    def build_message(message)
      parts = [message]
      parts << "source: #{source_type}" if source_type
      parts << "target: #{target_type}" if target_type
      parts.join(' (') + (parts.length > 1 ? ')' : '')
    end
  end

  # Error raised when a file is not found
  class FileNotFoundError < Error
    attr_reader :path

    def initialize(path)
      @path = path
      super("File not found: #{path}")
    end
  end

  # Error raised when an include directive's target cannot be located.
  # Honors the +missing_include+ policy: +:error+ raises this; +:warn+,
  # +:silent+, and +:passthrough+ swallow it.
  class IncludeNotFoundError < Error
    attr_reader :target

    def initialize(target)
      @target = target
      super("Include target not found: #{target}")
    end
  end

  # Error raised when an include chain exceeds the configured depth limit.
  class IncludeDepthExceededError < Error
    attr_reader :depth, :target

    def initialize(target:, depth:, max:)
      @target = target
      @depth = depth
      super("Include depth #{depth} exceeds max #{max} at #{target}")
    end
  end

  # Error raised when a cycle is detected in the include graph.
  # The chain is the list of files leading back to the repeated target.
  class CircularIncludeError < Error
    attr_reader :chain, :target

    def initialize(target:, chain:)
      @target = target
      @chain = chain
      super("Circular include detected: #{chain.join(' -> ')} -> #{target}")
    end
  end

  # Error raised when an include target escapes the resolver's safe base
  # directory and +allow_unsafe_includes+ is not set.
  class UnsafeIncludeError < Error
    attr_reader :target

    def initialize(target)
      @target = target
      super("Unsafe include path blocked: #{target}")
    end
  end

  # Error raised when an include target exceeds the resolver's size limit.
  class IncludeTooLargeError < Error
    attr_reader :target

    def initialize(target)
      @target = target
      super("Include target too large to read: #{target}")
    end
  end

  # Error raised when a requested format is not supported
  #
  # @example
  #   raise UnsupportedFormatError.new(:docx, available: [:html, :markdown])
  #
  class UnsupportedFormatError < Error
    attr_reader :requested_format, :available_formats

    # Create a new unsupported format error
    #
    # @param format [Symbol, String] The requested format
    # @param available [Array<Symbol>] List of available formats
    def initialize(format, available: [])
      @requested_format = format
      @available_formats = available
      super(build_message)
    end

    private

    def build_message
      msg = "Format '#{requested_format}' is not supported"
      msg += ". Available formats: #{available_formats.join(', ')}" if available_formats.any?
      msg
    end
  end

  # Errors raised by the unified content-graph reference resolver.
  # See Coradoc::Reference for the full ontology.
  module Reference
    # Base class for reference-resolution errors. All subclasses inherit
    # from here so callers can rescue the family with one +rescue+ clause.
    class Error < Coradoc::Error; end

    # Raised when no catalog knew the requested Address and the
    # +missing:+ policy is :error.
    class MissingReferenceError < Error
      attr_reader :address

      def initialize(message = nil, address: nil)
        @address = address
        super(message || "Reference not found: #{address}")
      end
    end

    # Raised when multiple catalogs matched an Address and the
    # +ambiguous:+ policy is :error.
    class AmbiguousReferenceError < Error
      attr_reader :address, :candidates

      def initialize(message = nil, address: nil, candidates: nil)
        @address = address
        @candidates = candidates
        super(message || "Reference is ambiguous: #{address}")
      end
    end

    # Raised when the catalog index is malformed — a programmer
    # error, not a runtime condition. Surfaces as a clear message
    # rather than a vague NoMethodError.
    class InvalidCatalogError < Error; end
  end
end
