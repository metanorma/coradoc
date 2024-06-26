require "uri"

module Coradoc
  module Element
    module Inline
      class Link < Base
        attr_accessor :path, :title, :name, :right_constrain

        declare_children :path, :title, :name

        def initialize(options = {})
          @path = options.fetch(:path, nil)
          @title = options.fetch(:title, nil)
          @name = options.fetch(:name, nil)
          @right_constrain = options.fetch(:right_constrain, false)
        end

        def to_adoc
          link = @path
          unless @path.to_s&.match?(URI::DEFAULT_PARSER.make_regexp)
            link = "link:#{link}"
          end

          name_empty = @name.to_s.empty?
          title_empty = @title.to_s.empty?
          valid_empty_name_link = link.start_with?(%r{https?://})

          link << if name_empty && !title_empty
                    "[#{@title}]"
                  elsif !name_empty
                    "[#{@name}]"
                  elsif valid_empty_name_link && !right_constrain
                    ""
                  else
                    "[]"
                  end
          link
        end
      end
    end
  end
end
