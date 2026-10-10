# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    # AsciiDoc lint rules (#165). Each rule checks the AsciiDoc model
    # tree in a model-driven way — no text scanning. Rules self-register
    # into Coradoc::Lint.registry when this file is required; adding a
    # rule is adding one file under lint/ plus its require here.
    #
    # NOTE: a "list starts deeper than level 1" rule is structurally
    # unobservable here — the parser canonicalizes depth markers
    # (#285), so a lone '**' list already reads as level 1 on the
    # model tree. That concern lives in the parser/serializer, not
    # in a lint.
    module Lint
      require_relative 'lint/heading_levels'
      require_relative 'lint/document_title'
      require_relative 'lint/empty_section'
      require_relative 'lint/duplicate_ids'

      RULES = [HeadingLevels, DocumentTitle, EmptySection,
               DuplicateIds].freeze

      RULES.each { |rule| Coradoc::Lint.registry.register(rule) }
    end
  end
end
