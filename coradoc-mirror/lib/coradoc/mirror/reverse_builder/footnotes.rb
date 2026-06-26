# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      # The `footnotes` block is a structural trailing container; it has
      # no CoreModel equivalent (each entry is built separately). Returns
      # nil so build_content filters it out.
      class Footnotes < Base
        registers 'footnotes'

        def build(_node)
          nil
        end
      end
    end
  end
end
