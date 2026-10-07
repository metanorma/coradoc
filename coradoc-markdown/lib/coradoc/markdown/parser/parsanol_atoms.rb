# frozen_string_literal: true

require 'parsanol'

module Coradoc
  module Markdown
    module Parser
      # DSL surface for the Markdown parser. The custom atoms this
      # module once carried (Output, DynamicOutput, Lookbehind) are
      # retired: fixed-yield sites use Atoms::Constant, callable
      # transforms moved to the AST phase, and guards use the
      # built-in Atoms::Lookbehind — the grammar is fully
      # wire-expressible (parsanol-ruby#163).
      module ParsanolAtoms
      end
    end
  end
end

# Additive DSL surface (no overrides): exposes the remaining custom
# DSL on every atom. The custom DynamicOutput/Lookbehind atoms are
# GONE — raw captures decode in the AST phase and guards use the
# built-in Parsanol::Atoms::Lookbehind (literal + regex forms,
# parsanol >= 1.3.77) — parsanol-ruby#163.
module Parsanol
  module Atoms
    module DSL
      # Matches self (discarding its captures) and yields a fixed
      # value — built on Atoms::Constant so the shape is
      # wire-expressible for the native engine (rs#137 follow-up).
      def output(value)
        ignore >> Constant.new(value)
      end
    end
  end
end
