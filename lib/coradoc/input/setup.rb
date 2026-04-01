require_relative "../converter"

module Coradoc
  module Input
    @processors ||= {}
    extend Converter::CommonInputOutputMethods unless respond_to?(:define)
  end
end
