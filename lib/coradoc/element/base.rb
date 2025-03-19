module Coradoc
  module Element
    class Base
      # The idea here, is that HTML content generators may often introduce
      # a lot of unnecessary markup, that only makes sense in the HTML+CSS
      # context. The idea is that certain cases can be simplified, making it
      # so that the result is equivalent, but much simpler, allowing us to
      # generate a nicer AsciiDoc syntax for those cases.
      def simplify_block_content(content)
        content = Array(content)
        collected_content = []
        content.each do |i|
          case i
          when Coradoc::Element::Section
            return content unless i.safe_to_collapse?

            collected_content << i.anchor if i.anchor

            simplified = simplify_block_content(i.contents)

            if simplified && !simplified.empty?
              collected_content << simplified
            end
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

      def self.declare_children(*children)
        @children = (@children || []).dup + children
        access_children
      end

      # Make each child available for access
      def self.access_children
        @children.each do |child|
          attr_accessor child
        end
      end

      def self.visit(element, &block)
        element = yield element, :pre
        element = if element.respond_to? :visit
                    element.visit(&block)
                  elsif element.is_a? Array
                    element.map { |child| visit(child, &block) }.flatten.compact
                  elsif element.is_a? Hash
                    element.to_h do |k, v|
                      [visit(k, &block), visit(v, &block)]
                    end
                  else
                    element
                  end
        yield element, :post
      end

      def self.children_accessors
        @children || []
      end

      def children_accessors
        self.class.children_accessors
      end

      def visit(&block)
        children_accessors.each do |accessor|
          child = public_send(accessor)
          result = self.class.visit(child, &block)
          if result != child
            public_send(:"#{accessor}=", result)
          end
        end
        self
      end
    end
  end
end
