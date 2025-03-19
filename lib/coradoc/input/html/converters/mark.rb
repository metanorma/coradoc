module Coradoc::Input::Html
  module Converters
    class Mark < Markup
      def coradoc_class
        Coradoc::Element::Inline::Highlight
      end

      def markup_ancestor_tag_names
        %w[mark]
      end
    end

    register :mark, Mark.new
  end
end
