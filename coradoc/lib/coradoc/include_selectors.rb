# frozen_string_literal: true

module Coradoc
  # Pure-function selectors applied to resolved include content.
  #
  # Each selector owns exactly one transformation (MECE):
  #   Tags         // tag::X[] ... // end::X[] region extraction
  #   Lines        line-range selection (1..N;2;3..4)
  #   Indent       leading-whitespace normalization
  #   LevelOffset  section-level shift (applied AFTER parsing)
  #
  # Tags, Lines, and Indent take a String and return a String.
  # LevelOffset takes a parsed CoreModel and returns a new CoreModel.
  #
  # The processor orchestrates the order:
  #   1. Tags   (or Lines; Lines wins if both specified — SPEC 3.5)
  #   2. Indent
  #   3. parse → CoreModel
  #   4. LevelOffset
  module IncludeSelectors
    autoload :Tags, "#{__dir__}/include_selectors/tags"
    autoload :Lines, "#{__dir__}/include_selectors/lines"
    autoload :Indent, "#{__dir__}/include_selectors/indent"
    autoload :LevelOffset, "#{__dir__}/include_selectors/level_offset"
  end
end
