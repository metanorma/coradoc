# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      autoload :Base, "#{__dir__}/parser/base"
      autoload :Cache, "#{__dir__}/parser/cache"
    end
  end
end
