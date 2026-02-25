# frozen_string_literal: true

# require "lutaml/model"

module Coradoc
  module AsciiDoc
    module Model
      # Base class for all Coradoc model objects.
      #
      # The Base class provides common functionality for all document model elements,
      # including serialization support, tree traversal, and attribute management.
      #
      # All model classes inherit from this class to get:
      # - Lutaml::Model serialization capabilities
      # - ComparableModel functionality
      # - Visit pattern for tree traversal
      # - Polymorphic content serialization
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the element
      #
      # @example Implementing a custom model class
      #   class CustomBlock < Coradoc::AsciiDoc::Model::Base
      #     attribute :content, :string
      #     attribute :children, array: true
      #   end
      #
      # @example Using the visit pattern
      #   doc.visit do |element, phase|
      #     puts "#{phase}: #{element.class}" if element.is_a?(Paragraph)
      #   end
      #
      class Base < Lutaml::Model::Serializable
        include Lutaml::Model::ComparableModel

        attribute :id, :string

        # Generate a warning message whenever this method is called.
        def simplify_block_content(content)
          warn '[DEPRECATION] #simplify_block_content is called inside a Lutaml Model.  This is still a WIP.'
          # print part of the stack trace
          caller_locations(1, 3).each do |location|
            warn "  #{location.path}:#{location.lineno} in #{location.label}"
          end

          content
        end

        # Visit pattern for traversing the document tree
        def self.visit(element, &block)
          return element if element.nil?

          element = yield element, :pre
          element = if element.respond_to?(:visit)
                      element.visit(&block)
                    elsif element.is_a?(Array)
                      element.map { |child| visit(child, &block) }
                             .flatten.compact
                    elsif element.is_a?(Hash)
                      result = {}
                      element.each do |k, v|
                        result[k] = visit(v, &block)
                      end
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

        # Serialize polymorphic content to AsciiDoc string
        # Handles: Arrays, Strings, nil, and model objects
        # Raises ArgumentError for unknown types to force proper handling
        def serialize_content(content)
          case content
          when Array
            content.map { |elem| serialize_content(elem) }.join
          when String
            content
          when nil
            ''
          when Coradoc::AsciiDoc::Model::Base, Lutaml::Model::Serializable
            # All model objects should respond to to_adoc
            content.to_adoc
          else
            # This is a programming error - we received an unexpected type
            raise ArgumentError,
                  "Cannot serialize #{content.class.name} in content. " \
                  'Expected String, nil, Array, Coradoc::AsciiDoc::Model::Base, or ' \
                  "Lutaml::Model::Serializable. Got: #{content.inspect[0..100]}"
          end
        end

        # Does a shallow attribute dump of the object,
        # for use when instantiating a new object (e.g. of a subclass) from an
        # existing one.
        def to_h
          self.class.attributes.keys.each_with_object({}) do |attribute, acc|
            acc[attribute] = public_send(attribute)
          end
        end

        # Serialize this model element to AsciiDoc
        #
        # This is the unified serialization method for all Model objects.
        # It uses the ElementRegistry system which provides serializers
        # for each model type.
        #
        # @return [String] AsciiDoc representation of this element
        #
        # @example Serialize a paragraph to AsciiDoc
        #   para = Coradoc::AsciiDoc::Model::Paragraph.new("Hello World")
        #   para.to_adoc # => "Hello World\n"
        #
        def to_adoc
          Coradoc::AsciiDoc::Serializer.serialize(self)
        end
      end
    end
  end
end
