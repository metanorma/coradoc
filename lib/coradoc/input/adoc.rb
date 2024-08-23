require "coradoc/input"

module Coradoc
  module Input::Adoc
    def self.processor_id
      :adoc
    end

    def self.processor_match?(filename)
      %w[.adoc].any? { |i| filename.downcase.end_with?(i) }
    end

    def self.processor_execute(input, _options = {})
      Coradoc::Parser.parse(input)
    end

    Coradoc::Input.define(self)
  end
end
