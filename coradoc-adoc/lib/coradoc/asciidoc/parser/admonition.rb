# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      module Admonition
        # Match a single style name case-insensitively. Each character
        # class `[Xx]` lets the same alternation accept +note+, +Note+,
        # and +NOTE+ without three separate str() branches per style.
        def case_insensitive_str(s)
          s.chars.reduce(nil) do |acc, ch|
            node = match("[#{ch.upcase}#{ch.downcase}]")
            acc.nil? ? node : (acc >> node)
          end
        end

        def admonition_type
          styles = Coradoc::AsciiDoc::Transform::ElementTransformers::AdmonitionStyles.all_styles
          styles.reduce(nil) do |acc, style|
            matcher = case_insensitive_str(style)
            acc.nil? ? matcher : (acc | matcher)
          end
        end

        def admonition_line
          admonition_type.as(:admonition_type) >> str(': ') >>
            (text_any.as(:text) >>
            line_ending.as(:line_break)
            ).repeat(1)
            .as(:content)
        end
      end
    end
  end
end
