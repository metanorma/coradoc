# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      # Context object passed through serialization pipeline
      #
      # Provides a type-safe, extensible way to pass serialization state
      # through the document tree, replacing the opaque options hash.
      #
      # @example Create a context
      #   context = SerializationContext.new(
      #     format: :adoc,
      #     last_element: false,
      #     depth: 0
      #   )
      #
      # @example Create context for a child
      #   child_context = context.for_child(0, 3)
      #
      # @example Add custom option
      #   context_with_option = context.with_option(:preserve_whitespace, true)
      #
      class SerializationContext
        # Output format (:adoc, :html, :xml, etc.)
        #
        # @return [Symbol] the output format
        attr_reader :format

        # Whether this is the last element in its container
        # Used to control trailing newlines and spacing
        #
        # @return [Boolean] true if last element
        attr_reader :last_element

        # Nesting depth in the document tree
        # Can be used for indentation or formatting decisions
        #
        # @return [Integer] current depth
        attr_reader :depth

        # Parent context (if any)
        # Allows traversing up the context chain
        #
        # @return [SerializationContext, nil] parent context
        attr_reader :parent

        # Additional options hash for extension
        # Provides backward compatibility and extensibility
        #
        # @return [Hash] additional options
        attr_reader :options

        # Create a new serialization context
        #
        # @param format [Symbol] Output format
        # @param last_element [Boolean] Whether this is the last element
        # @param depth [Integer] Nesting depth
        # @param parent [SerializationContext, nil] Parent context
        # @param options [Hash] Additional options
        def initialize(format: :adoc, last_element: false, depth: 0,
                       parent: nil, options: {})
          @format = format
          @last_element = last_element
          @depth = depth
          @parent = parent
          @options = options.freeze
          freeze
        end

        # Create a context for a child element
        #
        # Automatically adjusts depth and calculates last_element
        # based on the child's position.
        #
        # @param child_index [Integer] Index of this child (0-based)
        # @param total_children [Integer] Total number of children
        # @return [SerializationContext] Context for the child
        #
        # @example
        #   children.each_with_index do |child, i|
        #     serialize(child, context.for_child(i, children.length))
        #   end
        def for_child(child_index, total_children)
          SerializationContext.new(
            format: format,
            last_element: child_index == total_children - 1,
            depth: depth + 1,
            parent: self,
            options: options
          )
        end

        # Create a context with an additional option
        #
        # Returns a new context with the option added to the options hash.
        # Does not mutate the original context.
        #
        # @param key [Symbol] Option key
        # @param value [Object] Option value
        # @return [SerializationContext] New context with the option
        #
        # @example Add a custom option
        #   context.with_option(:preserve_whitespace, true)
        def with_option(key, value)
          SerializationContext.new(
            format: format,
            last_element: last_element,
            depth: depth,
            parent: parent,
            options: options.merge(key => value)
          )
        end

        # Create a context for a different format
        #
        # @param new_format [Symbol] New format
        # @return [SerializationContext] Context with new format
        #
        # @example Switch to HTML format
        #   html_context = context.with_format(:html)
        def with_format(new_format)
          SerializationContext.new(
            format: new_format,
            last_element: last_element,
            depth: depth,
            parent: parent,
            options: options
          )
        end

        # Create a context with last_element set to true
        #
        # @return [SerializationContext] Context as last element
        def as_last_element
          return self if last_element

          SerializationContext.new(
            format: format,
            last_element: true,
            depth: depth,
            parent: parent,
            options: options
          )
        end

        # Check if we're inside a table cell
        #
        # Traverses up the parent chain to detect table context.
        #
        # @return [Boolean] true if in a table cell
        #
        # @example
        #   if context.in_table_cell?
        #     # Don't add block-level spacing
        #   end
        def in_table_cell?
          return false unless parent

          # Check if any ancestor is a table
          current = parent
          while current
            return true if current.options[:in_table] == true

            current = current.parent
          end
          false
        end

        # Get an option value
        #
        # @param key [Symbol] Option key
        # @param default [Object] Default value if not found
        # @return [Object] Option value or default
        #
        # @example
        #   preserve = context.option(:preserve_whitespace, false)
        def option(key, default = nil)
          options.fetch(key, default)
        end

        # Check if an option is present
        #
        # @param key [Symbol] Option key
        # @return [Boolean] true if option exists
        def has_option?(key)
          options.key?(key)
        end

        # Check if this is the root context (no parent)
        #
        # @return [Boolean] true if root
        def root?
          parent.nil?
        end

        # Create a root context for a new serialization
        #
        # @param format [Symbol] Output format
        # @param options [Hash] Additional options
        # @return [SerializationContext] Root context
        #
        # @example
        #   context = SerializationContext.root(format: :adoc)
        def self.root(format: :adoc, options: {})
          new(format: format, last_element: false, depth: 0, parent: nil, options: options)
        end

        # Backward compatibility: convert options hash to context
        #
        # @param options_or_context [Hash, SerializationContext] Options or context
        # @return [SerializationContext] Serialization context
        #
        # @example Convert options hash
        #   context = SerializationContext.from_options(last_element: true)
        def self.from_options(options_or_context)
          return options_or_context if options_or_context.is_a?(SerializationContext)

          new(
            format: options_or_context.fetch(:format, :adoc),
            last_element: options_or_context.fetch(:last_element, false),
            depth: options_or_context.fetch(:depth, 0),
            parent: nil,
            options: options_or_context
          )
        end

        # String representation for debugging
        #
        # @return [String] Debug string
        def inspect
          "#<#{self.class.name} format=#{format} last_element=#{last_element} depth=#{depth}>"
        end
        alias to_s inspect
      end
    end
  end
end
