module Coradoc
  module Input::Html
    class Error < StandardError
    end

    class UnknownTagError < Error
    end

    class InvalidConfigurationError < Error
    end
  end
end
