module Coradoc
  module Element
    class ListItemDefinition < Base
      attr_accessor :id, :terms, :contents

      declare_children :id, :terms, :contents

      def initialize(terms, contents, options = {})
        @terms = terms
        @contents = contents
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
      end

      def to_adoc(delimiter: nil)
        anchor = @anchor.nil? ? "" : @anchor.to_adoc.to_s
        content = ""
        if (@terms.is_a?(Array) && @terms.size == 1) || !@terms.is_a?(Array)
          t = Coradoc::Generator.gen_adoc(@terms)
          content << "#{anchor}#{t}#{delimiter} "
        else
          @terms.map do |term|
            t = Coradoc::Generator.gen_adoc(term)
            content << "#{t}#{delimiter}\n"
          end
        end
        d = Coradoc::Generator.gen_adoc(@contents)
        content << "#{d}\n"
      end
    end
  end
end
