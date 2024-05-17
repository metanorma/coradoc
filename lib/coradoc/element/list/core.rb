require_relative "../inline/anchor"
require_relative "core"

module Coradoc
  module Element
    module List
      class Core
        attr_reader :items, :prefix, :id, :ol_count, :anchor

        def initialize(items, options = {})
          @items = items
          @items = [@items] unless @items.is_a?(Array)
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @ol_count = options.fetch(:ol_count, 1)
          @attrs = options.fetch(:attrs, AttributeList.new)
        end

        def to_adoc
          anchor = @anchor.nil? ? "" : @anchor.to_adoc.to_s
          attrs = @attrs.to_adoc(false).to_s
          content = "\n"
          @items.each do |item|
            c = Coradoc::Generator.gen_adoc(item)
            if !c.empty?
              content << prefix.to_s
              content << " " if c[0]!=" "
              content << c
            end
          end
          "\n#{anchor}#{attrs}" + content
        end
      end
    end
  end
end
