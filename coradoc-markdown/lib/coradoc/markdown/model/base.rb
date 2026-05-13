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

      # Additional attributes from IAL (typed key-value pairs)
      attribute :attributes, NamedValue, collection: true, default: []

      # Visit pattern for traversing the document tree
      def self.visit(element, &block)
        return element if element.nil?

        element = yield element, :pre
        element = case element
                  when self
                    element.visit(&block)
                  when Array
                    element.map { |child| visit(child, &block) }.flatten.compact
                  when Hash
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
    end
  end
end
