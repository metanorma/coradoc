# frozen_string_literal: true

module Coradoc
  module Mirror
    # Open registry mapping CoreModel classes to handler modules.
    #
    # Replaces closed case/when dispatch with an extensible registry.
    # Third-party gems can register additional handlers without modifying
    # core classes (OCP).
    #
    # Lookup (including ancestor walking) is delegated to
    # `Coradoc::Dispatch.hierarchical`. This class keeps the Entry shape and
    # the handler-invocation semantics — those are mirror-specific.
    #
    # @example Registering a handler
    #   registry = Coradoc::Mirror.default_registry
    #   registry.register(MyCustomBlock, MyHandler)
    #
    # @example Creating a custom registry
    #   registry = Coradoc::Mirror::HandlerRegistry.new
    #   registry.register(Coradoc::CoreModel::ParagraphBlock, MyParagraphHandler)
    #
    class HandlerRegistry
      Entry = Struct.new(:handler, :method_name, :concat, :extra_kwargs,
                         keyword_init: true)

      def initialize
        @dispatch = Coradoc::Dispatch.hierarchical
      end

      # Register a handler for a CoreModel class.
      #
      # @param model_class [Class] CoreModel class to handle
      # @param handler [Module, Class, Proc] handler implementation.
      #   If a Module/Class, +method_name+ is called on it.
      #   If a Proc, called directly with (element, context:).
      # @param method_name [Symbol] method to call on handler (default: :call)
      # @param concat [Boolean] if true, handler result is an array to
      #   concat into content rather than a single item to append
      # @param extra_kwargs [Hash] additional keyword arguments passed
      #   to the handler
      def register(model_class, handler, method_name: :call, concat: false,
                   extra_kwargs: {})
        @dispatch.register(
          model_class,
          Entry.new(
            handler: handler,
            method_name: method_name,
            concat: concat,
            extra_kwargs: extra_kwargs
          )
        )
      end

      # Find the handler entry for a given CoreModel element.
      #
      # Walks the element's class ancestors (via Dispatch.hierarchical) to
      # find the most specific registered handler. This allows registering
      # a handler for a base class (e.g., Block) that applies to all
      # subclasses, while also registering specific handlers for subclasses.
      #
      # @param element [CoreModel::Base] element to find handler for
      # @return [Entry, nil]
      def entry_for(element)
        @dispatch.lookup(element.class)
      end

      def registered?(model_class)
        @dispatch.registered?(model_class)
      end

      # Invoke the handler for a given element.
      #
      # @param element [CoreModel::Base] element to handle
      # @param context [CoreModelToMirror] transformer context
      # @return [Array(result, concat_flag), nil] handler result or nil
      def handle(element, context:)
        entry = entry_for(element)
        return nil unless entry

        kwargs = { context: context }.merge(entry.extra_kwargs || {})

        result = case entry.handler
                 when Proc
                   entry.handler.call(element, context)
                 else
                   entry.handler.public_send(entry.method_name, element, **kwargs)
                 end

        [result, entry.concat]
      end
    end
  end
end
