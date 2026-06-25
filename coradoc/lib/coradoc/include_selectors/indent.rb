# frozen_string_literal: true

module Coradoc
  module IncludeSelectors
    # Indent normalization. Two modes per asciidoctor:
    #
    #   indent=0   strip all leading whitespace from every line
    #   indent=N   normalize leading whitespace to exactly N spaces
    #   nil        pass through unchanged
    module Indent
      # @param text [String]
      # @param options [Coradoc::CoreModel::IncludeOptions]
      # @return [String]
      def self.call(text, options:)
        return text if options.indent.nil?

        if options.indent.zero?
          strip_all(text)
        else
          reindent(text, options.indent)
        end
      end

      class << self
        private

        def strip_all(text)
          text.lines.map { |line| line.sub(/\A[[:space:]]+/, '') }.join
        end

        def reindent(text, target)
          min_indent = text.lines
                           .reject { |l| l.strip.empty? }
                           .map { |l| l.length - l.lstrip.length }
                           .min || 0

          pad = ' ' * target
          text.lines.map do |line|
            stripped = strip_common_prefix(line, min_indent)
            if stripped.strip.empty?
              stripped.strip + "\n"
            else
              pad + stripped
            end
          end.join
        end

        def strip_common_prefix(line, count)
          line.sub(/\A[[:space:]]{0,#{count}}/, '')
        end
      end
    end
  end
end
