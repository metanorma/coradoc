require_relative "../converter"

module Coradoc
  module Output
    @processors ||= {}
    extend Converter::CommonInputOutputMethods unless respond_to?(:define)
  end
end
