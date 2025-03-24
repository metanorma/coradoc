module Coradoc
  module Input
    module Html
      class Error < StandardError
      end

      class UnknownTagError < Error
      end

      class InvalidConfigurationError < Error
      end
    end
  end
end
