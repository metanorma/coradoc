# frozen_string_literal: true

module Coradoc
  module Html
    # HTML lint rules: model-driven checks over the parsed CoreModel
    # element array that Coradoc::Html.parse produces. Rules
    # self-register into Coradoc::Lint.registry when required.
    module Lint
      require_relative 'lint/heading_levels'
      require_relative 'lint/image_alt'

      RULES = [HeadingLevels, ImageAlt].freeze

      RULES.each { |rule| Coradoc::Lint.registry.register(rule) }
    end
  end
end
