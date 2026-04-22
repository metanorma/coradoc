# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    # Custom error class for parsing failures
    #
    # Provides detailed context about where parsing failed, including
    # line number, column position, and source snippet.
    #
    # @example Raising a parse error
    #   raise Coradoc::AsciiDoc::ParseError.new(
    #     "Unexpected token",
    #     line: 42,
    #     column: 10,
    #     source: "line with error",
    #     suggestion: "Did you mean X?"
    #   )
    #
    class ParseError < Error
      # @return [Integer, nil] Line number where error occurred
      attr_reader :line

      # @return [Integer, nil] Column position where error occurred
      attr_reader :column

      # @return [String, nil] Source line containing the error
      attr_reader :source_line

      # @return [String, nil] Helpful suggestion for fixing the error
      attr_reader :suggestion

      # @return [String, nil] Full source content (for multi-line context)
      attr_reader :source

      # @return [Exception, nil] Original exception that caused this error
      attr_reader :cause

      # Create a new ParseError
      #
      # @param message [String] Error description
      # @param line [Integer, nil] Line number (1-indexed)
      # @param column [Integer, nil] Column position (1-indexed)
      # @param source_line [String, nil] The source line containing the error
      # @param source [String, nil] Full source content
      # @param suggestion [String, nil] Suggestion for fixing the error
      # @param cause [Exception, nil] Original exception that caused this error
      def initialize(message, line: nil, column: nil, source_line: nil, source: nil, suggestion: nil, cause: nil)
        @line = line
        @column = column
        @source_line = source_line
        @source = source
        @suggestion = suggestion
        @cause = cause

        full_message = build_full_message(message)
        super(full_message)

        set_backtrace(cause.backtrace) if cause&.backtrace
      end

      # Build a formatted error message with context
      #
      # @param base_message [String] The base error message
      # @return [String] Formatted error message with location context
      def build_full_message(base_message)
        parts = [base_message]

        if line && column
          parts << "at line #{line}, column #{column}"
        elsif line
          parts << "at line #{line}"
        end

        if source_line
          parts << "\n  > #{source_line}"
          parts << "  > #{' ' * (column - 1)}^" if column&.positive?
        end

        parts << "\n  Suggestion: #{suggestion}" if suggestion

        parts.join("\n")
      end

      # Create a ParseError from a Parslet exception
      #
      # @param exception [Parslet::ParseFailed] The Parslet exception
      # @param source [String] The original source text
      # @return [ParseError] A new ParseError with extracted context
      def self.from_parslet(exception, source = nil)
        return exception if exception.is_a?(ParseError)

        line, column = extract_location(exception)
        source_line = extract_source_line(source, line)
        suggestion = generate_suggestion(exception)

        new(
          exception.message,
          line: line,
          column: column,
          source_line: source_line,
          source: source,
          suggestion: suggestion,
          cause: exception
        )
      rescue StandardError
        # If we can't extract details, wrap the original exception
        new(exception.message, cause: exception)
      end

      # Extract line and column from Parslet error
      #
      # @param exception [Parslet::ParseFailed] The Parslet exception
      # @return [Array<Integer, Integer>] Line and column numbers
      def self.extract_location(exception)
        return [nil, nil] unless exception.respond_to?(:cause)

        cause = exception.cause
        if cause.respond_to?(:source_line) && cause.respond_to?(:source_column)
          [cause.source_line, cause.source_column]
        else
          [nil, nil]
        end
      end

      # Extract the relevant source line
      #
      # @param source [String, nil] Full source text
      # @param line [Integer, nil] Line number
      # @return [String, nil] The source line
      def self.extract_source_line(source, line)
        return nil if source.nil? || line.nil?

        lines = source.split("\n")
        lines[line - 1] if line.positive? && line <= lines.length
      end

      # Generate a helpful suggestion based on the error
      #
      # @param exception [Exception] The parsing exception
      # @return [String, nil] A suggestion string
      def self.generate_suggestion(exception)
        message = exception.message.to_s.downcase

        case message
        when /expected.*heading/
          "Make sure headings start with '=' followed by a space"
        when /expected.*list/
          "List items should start with '*', '.', or a term followed by '::'"
        when /expected.*table/
          "Tables require '|===' delimiters and '|' for cell separators"
        when /expected.*block/
          'Block delimiters should be 4 identical characters (----, ====, etc.)'
        when /expected.*attribute/
          "Attributes should be in the format ':name: value'"
        when /unexpected.*end/
          'Check for missing closing delimiters or incomplete syntax'
        end
      end
    end
  end
end
