module Coradoc
  module Element
    module List
      class Definition < Core
        attr_reader :items, :delimiter

        def initialize(items, options = {})
          @items = items
          @delimiter = options.fetch(:delimiter, "::")
          # super(items, options)
        end

        def prefix
          @delimiter
        end

        def to_adoc
          content = "\n"
          @items.each do |item|
            content << item.to_adoc(@delimiter)
          end
          content
        end
      end
    end
  end
end
