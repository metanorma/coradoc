# frozen_string_literal: true

module Coradoc
  # Pure-function module for relative-path arithmetic across output keys.
  #
  # Every SSG wrapper (VitePress, Hugo, Astro) needs to compute "how many
  # directories up do I walk to reach the site root from this output?".
  # The answer is the segment count of the source output_key. Everything
  # else (template, imports) is host-system-specific; this module owns
  # only the one piece of arithmetic that is genuinely shared.
  #
  # No state. No class. No knowledge of any specific SSG.
  #
  # @example Compute a VitePress import path
  #   Coradoc::RelativePath.from("author/iso/ref/foo", to: ".vitepress/theme")
  #   # => "../../../.vitepress/theme"
  module RelativePath
    module_function

    # Compute a relative path from an output_key to a site-root-relative
    # target.
    #
    # @param output_key [String, nil] site-relative key for the source
    #   page (e.g. "author/iso/ref/foo"). No leading slash, no extension.
    # @param to [String] destination path relative to the site root.
    # @return [String] the composed relative path.
    def from(output_key, to:)
      depth = output_key.to_s.count('/')
      ('../' * depth) + to.to_s
    end
  end
end
