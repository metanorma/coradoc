module Coradoc
  module Element
    class Base
      # The idea here, is that HTML content generators may often introduce
      # a lot of unnecessary markup, that only makes sense in the HTML+CSS
      # context. The idea is that certain cases can be simplified, making it
      # so that the result is equivalent, but much simpler, allowing us to
      # generate a nicer AsciiDoc syntax for those cases.
      def simplify_content(content)
        content = Array(content)
        collected_content = []
        content.each do |i|
          case i
          when Coradoc::Element::Section
            return content unless i.safe_to_collapse?

            collected_content += simplify_content(i.contents)
          else
            collected_content << i
          end
        end

        collected_content = collected_content.compact

        # We can safely do this optimization only if there's just one other
        # element inside this structure.
        if collected_content.length <= 1
          collected_content
        else
          content
        end
      end
    end
  end
end
