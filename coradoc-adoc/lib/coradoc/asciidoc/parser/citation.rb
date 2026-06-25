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
      end
    end
  end
end
