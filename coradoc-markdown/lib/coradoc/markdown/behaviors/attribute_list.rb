# frozen_string_literal: true

module Coradoc
  module Markdown
    module Behaviors
      # Hand-written behavior for AttributeList (IAL/ALD parsing, merging).
      module AttributeList
        def self.prepended(base)
          base.extend(ClassMethods)
        end

        # Parsing entry points.
        module ClassMethods
          # Parse an IAL string into an AttributeList
          # @param str [String] The IAL string (e.g., '{:.class #id key="val"}')
          # @return [AttributeList] Parsed attribute list
          def parse(str)
            return nil if str.nil? || str.empty?

            # Remove surrounding braces
            content = str.strip.gsub(/\A\{?:?|\}?\z/, '')

            attr_list = new

            # Check for ALD (has a name before colon)
            if content =~ /\A(\w+):\s*/
              attr_list.name = ::Regexp.last_match(1)
              content = ::Regexp.last_match.post_match
            end

            # Parse the content
            parse_attributes(content, attr_list)

            attr_list
          end

          def parse_attributes(content, attr_list)
            # Use shared IalParser for consistent parsing
            ParserUtil::IalParser.tokenize(content).each do |token|
              case token[:type]
              when :class
                attr_list.classes << token[:value]
              when :id
                attr_list.id = token[:value]
              when :attribute
                attr_list.attributes << NamedValue.new(name: token[:key], value: token[:value])
              end
            end
          end
        end

        # Merge another AttributeList into this one
        # @param other [AttributeList] The other attribute list to merge
        # @return [AttributeList] self for chaining
        def merge!(other)
          return self unless other

          self.id = other.id if other.id
          self.classes = (classes + other.classes).uniq
          merged = {}
          (attributes + other.attributes).each { |nv| merged[nv.name] = nv }
          self.attributes = merged.values
          self
        end

        # Create a merged copy
        # @param other [AttributeList] The other attribute list to merge
        # @return [AttributeList] New merged attribute list
        def merge(other)
          dup.merge!(other)
        end

        # Check if this has any attributes
        # @return [Boolean]
        def empty?
          id.nil? && classes.empty? && attributes.empty?
        end
      end
    end
  end
end
