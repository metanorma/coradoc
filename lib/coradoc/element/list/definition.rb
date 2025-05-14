module Coradoc
  module Element
    module List
      class Definition < Base
        attr_accessor :items, :delimiter

        declare_children :items

        def initialize(items:, delimiter: "::")
          @items = items
          @delimiter = delimiter
        end

        def prefix
          @delimiter
        end

        def to_adoc
          content = "\n"
          @items.each do |item|
            content << item.to_adoc(delimiter: @delimiter)
          end
          content
        end
      end
    end
  end
end
