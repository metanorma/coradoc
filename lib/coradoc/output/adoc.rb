module Coradoc
  module Output
    module Adoc
      def self.processor_id
        :adoc
      end

      def self.processor_match?(filename)
        %w[.adoc].any? { |i| filename.downcase.end_with?(i) }
      end

      def self.processor_execute(input, _options = {})
        input.transform_values { |i| Coradoc::Generator.gen_adoc(i) }
      end

      Coradoc::Output.define(self)
    end
  end
end
