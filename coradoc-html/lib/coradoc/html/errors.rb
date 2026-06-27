# frozen_string_literal: true

module Coradoc
  module Html
    module Errors
      class Error < Coradoc::Error; end
      class UnknownTagError < Error; end
      class InvalidConfigurationError < Error; end
    end
  end
end
