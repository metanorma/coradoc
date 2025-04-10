module Coradoc
  class Generator
    def self.gen_adoc(content)
      if content.is_a?(Array)
        content.map do |elem|
          Coradoc::Generator.gen_adoc(elem)
        end.join
      elsif content.respond_to? :to_asciidoc
        content.to_asciidoc
      elsif content.respond_to? :to_adoc
        content.to_adoc
      elsif content.is_a?(String)
        content
      elsif content.nil?
        ""
      elsif content.is_a?(Parslet::Slice)
        content.to_s
      end
    end
  end
end
