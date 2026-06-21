# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Shared helpers for rendering Callout-annotated verbatim blocks.
    #
    # Both the Markdown and HTML spokes need to (a) order callouts by their
    # numeric index and (b) strip AsciiDoc-style `<N>` markers from the
    # raw code so they don't leak as literal text in the output format.
    # Centralizing these operations here keeps the behavior consistent
    # across spokes and avoids copy-paste drift.
    module CalloutText
      module_function

      def ordered(callouts)
        Array(callouts).sort_by { |c| c.index || Float::INFINITY }
      end

      # Removes callout markers (`<N>`) from `code` for the indices
      # referenced by `callouts`. Returns `code` unchanged when no
      # callouts are provided or none carry a usable index, so literal
      # `<N>` sequences in code without callouts are preserved.
      def strip_markers(code, callouts)
        list = Array(callouts)
        return code if list.empty?

        indices = list.filter_map(&:index).uniq
        return code if indices.empty?

        pattern = /<\s*(?:#{indices.join('|')})\s*>/
        code.to_s.lines(chomp: true).map { |line| line.gsub(pattern, '').rstrip }.join("\n")
      end
    end
  end
end
