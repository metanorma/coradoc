# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # A list of content elements that provides unified content handling
      #
      # ContentList handles mixed content types (strings, TextElements, model objects)
      # and provides a consistent API for querying and manipulating content.
      #
      # @example Create from strings
      #   content = ContentList.new("Hello", "World")
      #   content.text # => "HelloWorld"
      #
      # @example Create from mixed types
      #   content = ContentList.new([
      #     "Hello ",
      #     Bold.new("World"),
      #     "!"
      #   ])
      #   content.text # => "Hello World!"
      #
      # @example Query by type
      #   bold_items = content.find_type(Inline::Bold)
      #
      # @example Iterate elements
      #   content.each do |element|
      #     puts element.class
      #   end
      #
      class ContentList
        include Enumerable

        # Get the raw items array
        #
        # @return [Array] The content items
        attr_reader :items

        # Create a new ContentList
        #
        # @param items [Array, String, Object] Content items to initialize with
        #
        # @example From strings
        #   ContentList.new("Hello", "World")
        #
        # @example From array
        #   ContentList.new(["Hello", Bold.new("World")])
        #
        # @example From nested array
        #   ContentList.new([["Hello", " "], "World"])
        #
        def initialize(*items)
          @items = normalize(items.flatten)
          freeze
        end

        # Create a ContentList from a single value
        #
        # @param value [Object] The content value
        # @return [ContentList] New ContentList
        #
        # @example From string
        #   ContentList.from("Hello")
        #
        # @example From array
        #   ContentList.from(["Hello", "World"])
        #
        def self.from(value)
          case value
          when ContentList
            value
          when Array
            new(*value)
          when nil
            new
          else
            new(value)
          end
        end

        # Iterate over content items
        #
        # @yield [Object] Each content item
        # @return [Enumerator] If no block given
        #
        # @example Iterate
        #   content.each { |item| puts item }
        #
        def each(&block)
          @items.each(&block)
        end

        # Add an item to the content
        #
        # @param item [Object] Item to add
        # @return [ContentList] Self for chaining
        #
        # @example Add item
        #   content << "more text"
        #
        # Note: This returns a new ContentList since ContentList is immutable
        #
        def <<(item)
          ContentList.new(*@items, coerce(item))
        end

        # Get all items as a plain string
        #
        # @return [String] All items joined as string
        #
        # @example Get text
        #   content.text # => "Hello World"
        #
        def text
          @items.map(&:to_s).join
        end
        alias to_str text
        alias to_s text

        # Find all items of a specific type
        #
        # @param type [Class, Module] Type to find
        # @return [Array] Items of the specified type
        #
        # @example Find bold items
        #   content.find_type(Inline::Bold)
        #
        def find_type(type)
          @items.select { |item| item.is_a?(type) }
        end

        # Check if content is empty
        #
        # @return [Boolean] true if no items
        #
        def empty?
          @items.empty?
        end

        # Get number of items
        #
        # @return [Integer] Number of items
        #
        def size
          @items.size
        end
        alias length size

        # Get item at index
        #
        # @param index [Integer] Index
        # @return [Object, nil] Item at index or nil
        #
        def [](index)
          @items[index]
        end

        # Get first item
        #
        # @return [Object, nil] First item or nil
        #
        def first
          @items.first
        end

        # Get last item
        #
        # @return [Object, nil] Last item or nil
        #
        def last
          @items.last
        end

        # Convert to array
        #
        # @return [Array] Items as array
        #
        def to_a
          @items.dup
        end

        # Join items with a separator
        #
        # @param sep [String] Separator
        # @return [String] Joined string
        #
        # @example Join with spaces
        #   content.join(" ") # => "Hello World"
        #
        def join(sep = '')
          @items.map(&:to_s).join(sep)
        end

        # Map over items
        #
        # @yield [Object] Each item
        # @return [Array] Mapped items
        #
        # @example Map
        #   content.map(&:class) # => [String, Bold, String]
        #
        def map(&block)
          @items.map(&block)
        end

        # Select items matching predicate
        #
        # @yield [Object] Each item
        # @return [Array] Selected items
        #
        # @example Select strings
        #   content.select { |i| i.is_a?(String) }
        #
        def select(&block)
          @items.select(&block)
        end

        # Reject items matching predicate
        #
        # @yield [Object] Each item
        # @return [Array] Remaining items
        #
        def reject(&block)
          @items.reject(&block)
        end

        # Check if content includes an item
        #
        # @param item [Object] Item to check
        # @return [Boolean] true if item is in content
        #
        def include?(item)
          @items.include?(item)
        end

        # Check if content includes an item of a type
        #
        # @param type [Class, Module] Type to check
        # @return [Boolean] true if any item is of the type
        #
        # @example Check for bold
        #   content.include_type?(Inline::Bold)
        #
        def include_type?(type)
          @items.any? { |item| item.is_a?(type) }
        end

        # Concatenate another ContentList or array
        #
        # @param other [ContentList, Array] Other content to add
        # @return [ContentList] New ContentList with combined items
        #
        # @example Concatenate
        #   content + ContentList.new("more")
        #
        def +(other)
          other_items = other.is_a?(ContentList) ? other.items : Array(other)
          ContentList.new(*@items, *other_items)
        end

        # String representation for debugging
        #
        # @return [String] Debug string
        #
        def inspect
          "#<#{self.class.name} size=#{@items.size} items=#{@items.inspect}>"
        end

        # Two ContentLists are equal if their items are equal
        #
        # @param other [Object] Object to compare
        # @return [Boolean] true if equal
        #
        def ==(other)
          return false unless other.is_a?(ContentList)

          @items == other.items
        end
        alias eql? ==

        # Hash code for use in Hash keys
        #
        # @return [Integer] Hash code
        #
        def hash
          @items.hash
        end

        private

        # Normalize items to appropriate content types
        #
        # @param items [Array] Raw items
        # @return [Array] Normalized items
        #
        def normalize(items)
          items.map { |item| coerce(item) }
        end

        # Coerce an item to appropriate content type
        #
        # @param item [Object] Item to coerce
        # @return [Object] Coerced item
        #
        def coerce(item)
          case item
          when String
            # Convert string to TextElement
            TextElement.new(content: item)
          when TextElement, Model::Base
            # Already appropriate type
            item
          when nil
            # Skip nil items
            nil
          when Hash
            # Convert hash to TextElement if it has content key
            if item[:content] || item['content']
              TextElement.from_hash(item)
            else
              TextElement.new(content: item.inspect)
            end
          when Array
            # Flatten nested arrays
            normalize(item)
          else
            # Try to convert to string, then to TextElement
            TextElement.new(content: item.to_s)
          end
        end
      end
    end
  end
end
