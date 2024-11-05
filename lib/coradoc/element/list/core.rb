require_relative "../inline/anchor"
require_relative "core"

module Coradoc
  module Element
    module List
      class Core < Base
        attr_accessor :items, :prefix, :id, :ol_count, :anchor

        declare_children :items, :anchor, :id

        def initialize(items, options = {})
          @items = items
          @items = [@items] unless @items.is_a?(Array)
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @ol_count = options.fetch(:ol_count, nil)
          if @ol_count.nil?
            m = @items.select do |i|
              i.is_a?(Coradoc::Element::ListItem) &&
                !i.marker.nil?
            end.first&.marker.to_s
            @ol_count = m.size
          end
          @ol_count = 1 if @ol_count.nil?
          @attrs = options.fetch(:attrs, AttributeList.new)
        end

        def to_adoc
          anchor = @anchor.nil? ? "" : @anchor.to_adoc.to_s
          attrs = @attrs.to_adoc(false).to_s
          content = "\n"
          @items.each do |item|
            c = Coradoc::Generator.gen_adoc(item)
            if !c.empty?
              # If there's a list inside a list directly, we want to
              # skip adding an empty list item.
              # See: https://github.com/metanorma/coradoc/issues/96
              unless item.is_a? List::Core
                content << prefix.to_s
                content << " " if c[0] != " "
              end
              content << c
            end
          end
          "\n#{anchor}#{attrs}" + content
        end
      end
    end
  end
end
