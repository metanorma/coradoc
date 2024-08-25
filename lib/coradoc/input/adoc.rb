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
      ast = Coradoc::Parser::Base.new.parse(input)
      Coradoc::Transformer.transform(ast[:document])
    end

    def self.processor_postprocess(input, options)
      if options[:output_processor] == :adoc
        Coradoc::Input::HTML::Cleaner.new.tidy(input)
      else
        input
      end
    end

    Coradoc::Input.define(self)
  end
end
