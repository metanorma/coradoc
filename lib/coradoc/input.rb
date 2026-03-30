require_relative "converter"

module Coradoc
  module Input
    @processors = {}
    extend Converter::CommonInputOutputMethods
  end
end

require "coradoc/input/adoc"
require "coradoc/input/docx"
require "coradoc/input/html"
