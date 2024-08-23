module Coradoc::ReverseAdoc
  module Converters
    class Code < Markup
      def coradoc_class
        Coradoc::Element::Inline::Monospace
      end

      def markup_ancestor_tag_names
        %w[code tt kbd samp var]
      end
    end

    register :code, Code.new
    register :tt, Code.new
    register :kbd, Code.new
    register :samp, Code.new
    register :var, Code.new
  end
end
