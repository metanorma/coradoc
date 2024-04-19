module Coradoc
  module Document
    module Inline
      class CrossReference
        attr_reader :href, :name

        def initialize(href, name = nil)
          @href = href
          @name = name
        end

        def to_adoc
          if @name.to_s.empty?
            "<<#{@href}>>"
          else
            "<<#{@href},#{@name}>>"
          end
        end
      end
    end
  end
end
