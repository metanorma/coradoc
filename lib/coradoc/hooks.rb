# frozen_string_literal: true

require 'securerandom'

module Coradoc
  # Plugin lifecycle hooks system for extending the document processing pipeline.
  #
  # This module provides a registry for hook callbacks that can be invoked
  # at various points in the document processing lifecycle:
  #
  # - before_parse / after_parse: Around text parsing
  # - before_transform / after_transform: Around model transformation
  # - before_serialize / after_serialize: Around serialization
  # - on_error: When errors occur
  #
  # @example Registering a hook
  #   Coradoc::Hooks.register(:before_parse) do |content, format:, **options|
  #     puts "Parsing #{content.length} characters of #{format} content"
  #     content
  #   end
  #
  # @example Registering a logging hook
  #   Coradoc::Hooks.register(:after_transform) do |model, direction:|
  #     Logger.info("Transformed model: #{model.class}")
  #     model
  #   end
  #
  # @example Error handling hook
  #   Coradoc::Hooks.register(:on_error) do |error, context|
  #     Coradoc::Logger.error("Error in #{context[:phase]}: #{error.message}")
  #     nil # Return nil to not modify error handling
  #   end
  #
  module Hooks
    # Hook point definitions with descriptions
    HOOK_POINTS = {
      before_parse: 'Called before parsing text content. Receives (content, format:, **options). Should return modified content.',
      after_parse: 'Called after parsing. Receives (model, format:, **options). Should return modified model.',
      before_transform: 'Called before transforming model. Receives (model, direction:, **options). Should return modified model.',
      after_transform: 'Called after transforming model. Receives (model, direction:, **options). Should return modified model.',
      before_serialize: 'Called before serializing model. Receives (model, format:, **options). Should return modified model.',
      after_serialize: 'Called after serializing. Receives (output, format:, **options). Should return modified output.',
      on_error: 'Called when an error occurs. Receives (error, context). Can re-raise or return fallback value.'
    }.freeze

    class << self
      # Register a callback for a hook point.
      #
      # @param hook_point [Symbol] The hook point name (e.g., :before_parse)
      # @param priority [Integer] Execution priority (lower = earlier). Default: 100
      # @param name [String, nil] Optional name for the hook (for removal)
      # @yield The callback block
      # @yieldparam args Variable arguments depending on hook point
      # @return [String] Hook ID for later removal
      #
      # @example Register with priority
      #   Coradoc::Hooks.register(:before_parse, priority: 50) do |content, **|
      #     # High priority - runs early
      #     content
      #   end
      #
      def register(hook_point, priority: 100, name: nil, &block)
        validate_hook_point!(hook_point)
        validate_block!(block, hook_point)

        hook_id = name || generate_hook_id(hook_point)
        registry[hook_point] ||= []
        registry[hook_point] << {
          id: hook_id,
          priority: priority,
          callback: block
        }
        # Sort by priority after insertion
        registry[hook_point].sort_by! { |h| h[:priority] }
        hook_id
      end

      # Remove a registered hook by ID.
      #
      # @param hook_point [Symbol] The hook point name
      # @param hook_id [String] The hook ID returned from #register
      # @return [Boolean] true if hook was found and removed
      #
      def remove(hook_point, hook_id)
        validate_hook_point!(hook_point)
        return false unless registry[hook_point]

        original_size = registry[hook_point].size
        registry[hook_point].reject! { |h| h[:id] == hook_id }
        registry[hook_point].size < original_size
      end

      # Remove all hooks for a hook point.
      #
      # @param hook_point [Symbol] The hook point name
      # @return [Integer] Number of hooks removed
      #
      def clear(hook_point)
        validate_hook_point!(hook_point)
        removed = registry[hook_point]&.size || 0
        registry.delete(hook_point)
        removed
      end

      # Remove all hooks from all hook points.
      #
      # @return [Integer] Total number of hooks removed
      #
      def clear_all
        total = registry.values.sum(&:size)
        @registry = {}
        total
      end

      # Check if any hooks are registered for a hook point.
      #
      # @param hook_point [Symbol] The hook point name
      # @return [Boolean]
      #
      def registered?(hook_point)
        validate_hook_point!(hook_point)
        registry[hook_point]&.any? || false
      end

      # List all registered hooks.
      #
      # @param hook_point [Symbol, nil] Filter by hook point, or nil for all
      # @return [Array<Hash>] Array of hook information
      #
      def list(hook_point = nil)
        if hook_point
          validate_hook_point!(hook_point)
          registry[hook_point]&.map { |h| h.merge(point: hook_point) } || []
        else
          registry.flat_map do |point, hooks|
            hooks.map { |h| h.merge(point: point) }
          end
        end
      end

      # Invoke all hooks for a hook point.
      #
      # @param hook_point [Symbol] The hook point name
      # @param args [Array] Arguments to pass to hooks
      # @return [Object] The (potentially modified) result from the last hook
      #
      # @example Invoke before_parse hooks
      #   content = Coradoc::Hooks.invoke(:before_parse, content, format: :asciidoc)
      #
      def invoke(hook_point, *args, **kwargs)
        validate_hook_point!(hook_point)
        return args.first if args.one? && !registry[hook_point]&.any?

        result = args.first
        registry[hook_point].each do |hook|
          result = invoke_hook(hook[:callback], result, args, kwargs)
        end
        result
      end

      # Invoke hooks with error handling.
      #
      # @param hook_point [Symbol] The hook point name
      # @param args [Array] Arguments to pass to hooks
      # @yield Block to execute with hook context
      # @return [Object] Result from the block or error handling
      #
      def with_hooks(hook_point, *args, **kwargs)
        validate_hook_point!(hook_point)

        modified_args = invoke(hook_point, *args, **kwargs)
        result = yield(*modified_args)

        # Invoke after_* hooks if applicable
        after_point = "after_#{hook_point.to_s.sub('before_', '')}".to_sym
        result = invoke(after_point, result, **kwargs) if HOOK_POINTS.key?(after_point)

        result
      rescue StandardError => e
        # Invoke on_error hooks
        invoke_error_hooks(e, hook_point, args, kwargs)
      end

      # Get hook point documentation.
      #
      # @param hook_point [Symbol, nil] The hook point name, or nil for all
      # @return [String, Hash] Documentation string or hash of all
      #
      def documentation(hook_point = nil)
        if hook_point
          validate_hook_point!(hook_point)
          HOOK_POINTS[hook_point]
        else
          HOOK_POINTS.dup
        end
      end

      private

      def registry
        @registry ||= {}
      end

      def validate_hook_point!(hook_point)
        return if HOOK_POINTS.key?(hook_point)

        valid_points = HOOK_POINTS.keys.join(', ')
        raise ArgumentError,
              "Unknown hook point: #{hook_point}. Valid points: #{valid_points}"
      end

      def validate_block!(block, hook_point)
        return if block

        raise ArgumentError,
              "Block required for hook registration: #{hook_point}"
      end

      def generate_hook_id(hook_point)
        "#{hook_point}_#{SecureRandom.hex(8)}"
      end

      def invoke_hook(callback, result, _args, kwargs)
        arity = callback.arity

        # For procs with **kwargs, arity is 1, but they still accept kwargs
        # For lambdas with **kwargs, arity is -2
        # We need to always try passing kwargs if present

        if kwargs.empty?
          # No kwargs to pass, just pass result
          case arity
          when 0
            callback.call
          else
            callback.call(result)
          end
        else
          # We have kwargs to pass
          case arity
          when 0
            # Block takes no args but we have kwargs - just call it
            callback.call
          when 1
            # Proc with **kwargs has arity 1, but needs kwargs passed
            # Also handles single-arg blocks that don't use kwargs
            callback.call(result, **kwargs)
          when 2
            # Block takes two positional args
            callback.call(result, kwargs)
          else
            # Lambda with **kwargs (arity -2) or other variable arity
            callback.call(result, **kwargs)
          end
        end
      rescue StandardError => e
        # Don't let a single hook failure break the pipeline
        # Log and continue with unmodified result
        Coradoc::Logger.warn("Hook failed: #{e.message}")
        result
      end

      def invoke_error_hooks(error, hook_point, args, kwargs)
        context = {
          hook_point: hook_point,
          args: args,
          kwargs: kwargs
        }

        if registry[:on_error]&.any?
          registry[:on_error].each do |hook|
            result = hook[:callback].call(error, context)
            return result if result
          end
        end

        # Re-raise if no error hook handled it
        raise error
      end
    end
  end
end
