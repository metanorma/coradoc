# frozen_string_literal: true

module Coradoc
  module CoreModel
    class FrontmatterBlock
      # A single frontmatter key with its typed value tree. Map
      # containers inside a value hold nested FrontmatterEntry
      # children. Key order across a block's entries is significant
      # (round-trip fidelity) and is preserved by the entries
      # collection.
      class FrontmatterEntry < Base
        attribute :key, :string
        attribute :value, FrontmatterValue

        # Convenience: the native Ruby value behind this entry.
        def to_native
          value&.to_native
        end
      end
    end
  end
end
