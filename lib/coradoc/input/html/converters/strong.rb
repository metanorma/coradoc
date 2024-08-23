module Coradoc::Input::HTML
  module Converters
    class Strong < Markup
      def coradoc_class
        Coradoc::Element::Inline::Bold
      end

      def markup_ancestor_tag_names
        %w[strong b]
      end
    end

    register :strong, Strong.new
    register :b,      Strong.new
  end
end
