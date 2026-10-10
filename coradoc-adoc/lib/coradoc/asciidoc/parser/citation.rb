# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      module Citation
        # In `<<target,text>>`, the target is everything up to the first comma
        # or closing `>`. The text is everything else up to `>` — it can
        # contain commas, quotes, and any other punctuation.
        def cross_reference
          (str('<<') >>
            match('[^,>]').repeat(1).as(:href) >>
            (str(',') >> match('[^>]').repeat(0).as(:text)).maybe >>
            str('>>')
          ).as(:cross_reference)
        end

        # AsciiDoc escape: `\<<` produces the literal text `<<` without
        # firing the cross-reference rule. Without this, documentation that
        # shows AsciiDoc xref syntax as a literal example gets rewritten
        # into a broken link to a non-existent anchor.
        def escaped_xref
          str('\\') >> str('<<').as(:text)
        end

        # General AsciiDoc escape: \X (X punctuation, minus < for
        # escaped_xref and \ itself) yields the literal character X
        # without firing any inline rule (#281).
        def escape_char
          # Explicit class (all ASCII punctuation except < for
          # escaped_xref and \ itself): the native engine does not
          # compile && class intersections.
          str('\\') >> match("[!\"#$%&'()*+,\\-./:;=?@\\[\\]^_`{|}~]").as(:text)
        end
      end
    end
  end
end
