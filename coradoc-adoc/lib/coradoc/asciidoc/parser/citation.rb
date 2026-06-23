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
      end
    end
  end
end
