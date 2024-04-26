module Coradoc
  module Element
    module Inline
      class Link
        attr_reader :path, :title, :name

        def initialize(options = {})
          @path = options.fetch(:path, nil)
          @title = options.fetch(:title, nil)
          @name = options.fetch(:name, nil)
        end

        def to_adoc
          link = @path.to_s&.match?(URI::DEFAULT_PARSER.make_regexp) ? @path : "link:#{@path}"
          link << if @name.to_s.empty?
                    "[#{@title}]"
                  else
                    "[#{@name}]"
                  end
          link.prepend(" ")
          link
        end
      end
    end
  end
end
