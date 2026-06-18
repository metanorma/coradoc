# frozen_string_literal: true

module Coradoc
  module Markdown
    module Parser
      # Markdown frontmatter extractor.
      #
      # Delegates to the shared +Coradoc::CoreModel::FrontmatterBlock::TextSplitter+
      # — the single source of truth for the `---\n...\n---\n` convention
      # (DRY). Format gems retain a local parser module for discoverability
      # and as the seam for any format-specific extensions should they arise.
      module FrontmatterParser
        class << self
          def call(text)
            Coradoc::CoreModel::FrontmatterBlock::TextSplitter.call(text)
          end
        end

        Result = Coradoc::CoreModel::FrontmatterBlock::TextSplitter::Result
      end
    end
  end
end
