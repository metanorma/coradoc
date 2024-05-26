module Coradoc
  module Element
    module Inline
      class CrossReference < Base
        attr_accessor :href, :name

        declare_children :href, :name

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
