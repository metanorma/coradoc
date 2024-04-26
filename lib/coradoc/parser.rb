require_relative "parser/base"

module Coradoc
  module Parser
    class << self
      def parse(filename)
        Coradoc::Parser::Base.parse(filename)
      end
    end
  end
end
