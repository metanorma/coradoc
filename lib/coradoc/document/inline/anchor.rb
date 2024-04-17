module Coradoc
  module Document
    module Inline
      class Anchor
        attr_reader :id, :href, :title, :name

        def initialize(options = {})
          @id = options.fetch(:id,nil)
          @href = options.fetch(:href,nil)
          @title = options.fetch(:title, nil)
          @name = options.fetch(:name,nil)
        end

        def to_adoc
          if /^_Toc\d+$|^_GoBack$/.match @id
            ""
          elsif !@id.nil? && !@id.empty?
            "[[#{@id}]]"
          elsif @href.to_s.start_with?('#')
            @href = @href.sub(/^#/, "").gsub(/\s/, "").gsub(/__+/, "_")
            if @name.to_s.empty?
              "<<#{@href}>>"
            else
              "<<#{@href},#{@name}>>"
            end
          elsif @href.to_s.empty?
            @name
          else
            @name = @title if @name.to_s.empty?
            @href = "link:#{@href}" unless @href.to_s =~ URI::DEFAULT_PARSER.make_regexp
            link = "#{@href}[#{@name}]"
            link.prepend(' ')
            link
          end
        end
      end
    end
  end
end
