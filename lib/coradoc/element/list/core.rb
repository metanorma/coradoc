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
          @ol_count = options.fetch(:ol_count, 0)
          @attrs = options.fetch(:attrs, nil)
        end

        def to_adoc
          content = "\n"
          @items.each do |item|
            c = Coradoc::Generator.gen_adoc(item)
            if !c.empty?
              content << prefix.to_s
              content << c
            end
          end
          anchor = @anchor.nil? ? "" : @anchor.to_adoc.to_s
          attrs = @attrs.nil? ? "" : @attrs.to_adoc.to_s
          "\n#{anchor}#{attrs}" + content
        end
      end
    end
  end
end
