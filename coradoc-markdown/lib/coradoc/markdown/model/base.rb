# frozen_string_literal: true

module Coradoc
  module Markdown
    # Base class for all Markdown model objects.
    #
    # The Base class provides common functionality for all document model elements,
    # including serialization support and tree traversal.
    #
    class Base < Lutaml::Model::Serializable
      attribute :id, :string

      # Attribute list for IAL (Inline Attribute List) support
      # This allows attaching classes, id, and other attributes to elements
      # Example: {:.highlight #intro data-role="main"}
      attribute :attribute_list, :string

      # Classes from IAL (for convenience)
      attribute :classes, :string, collection: true

      # Additional attributes from IAL
      attribute :attributes, :hash, default: {}

      # Visit pattern for traversing the document tree
      def self.visit(element, &block)
        return element if element.nil?

        element = yield element, :pre
        element = if element.respond_to?(:visit)
                    element.visit(&block)
                  elsif element.is_a?(Array)
                    element.map { |child| visit(child, &block) }.flatten.compact
                  elsif element.is_a?(Hash)
                    result = {}
                    element.each { |k, v| result[k] = visit(v, &block) }
                    result
                  else
                    element
                  end
        yield element, :post
      end

      def visit(&block)
        self.class.attributes.each_key do |attr_name|
          child = public_send(attr_name)
          result = self.class.visit(child, &block)
          public_send(:"#{attr_name}=", result) if result != child
        end
        self
      end

      # Serialize polymorphic content to Markdown string
      def serialize_content(content)
        case content
        when Array
          content.map { |elem| serialize_content(elem) }.join
        when String
          content
        when nil
          ''
        else
          if content.respond_to?(:to_md)
            content.to_md
          else
            raise ArgumentError,
                  "Cannot serialize #{content.class.name} to Markdown. " \
                  'Expected String or object responding to #to_md.'
          end
        end
      end

      # Does a shallow attribute dump of the object
      def to_h
        self.class.attributes.keys.each_with_object({}) do |attribute, acc|
          acc[attribute] = public_send(attribute)
        end
      end

      # Serialize this model element to Markdown
      def to_md
        Coradoc::Markdown::Serializer.serialize(self)
      end
    end
  end
end
