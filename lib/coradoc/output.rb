require_relative "converter"

module Coradoc
  module Output
    @processors = {}
    extend Converter::CommonInputOutputMethods
  end
end

require "coradoc/output/adoc"
require "coradoc/output/coradoc_tree_debug"
