# frozen_string_literal: true

require 'securerandom'

module Coradoc
  module Hooks
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
      attr_accessor :strict_mode

      def register(hook_point, priority: 100, name: nil, &block)
        validate_hook_point!(hook_point)
        validate_block!(block, hook_point)

        hook_id = name || generate_hook_id(hook_point)
        registry[hook_point] ||= []
        registry[hook_point] << {
          id: hook_id,
          priority: priority,
          sequence: next_sequence,
          callback: block
        }
        registry[hook_point].sort_by! { |h| [h[:priority], h[:sequence]] }
        hook_id
      end

      def remove(hook_point, hook_id)
        validate_hook_point!(hook_point)
        return false unless registry[hook_point]

        original_size = registry[hook_point].size
        registry[hook_point].reject! { |h| h[:id] == hook_id }
        registry[hook_point].size < original_size
      end

      def clear(hook_point)
        validate_hook_point!(hook_point)
        removed = registry[hook_point]&.size || 0
        registry.delete(hook_point)
        removed
      end

      def clear_all
        total = registry.values.sum(&:size)
        @registry = {}
        @sequence_counter = nil
        total
      end

      def registered?(hook_point)
        validate_hook_point!(hook_point)
        registry[hook_point]&.any? || false
      end

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

      def invoke(hook_point, *args, **kwargs)
        validate_hook_point!(hook_point)
        return args.first if args.one? && !registry[hook_point]&.any?

        result = args.first
        registry[hook_point].each do |hook|
          result = invoke_hook(hook[:callback], result, args, kwargs)
        end
        result
      end

      def with_hooks(hook_point, *args, **kwargs)
        validate_hook_point!(hook_point)

        modified_args = invoke(hook_point, *args, **kwargs)
        result = yield(*modified_args)

        after_point = "after_#{hook_point.to_s.sub('before_', '')}".to_sym
        result = invoke(after_point, result, **kwargs) if HOOK_POINTS.key?(after_point)

        result
      rescue StandardError => e
        invoke_error_hooks(e, hook_point, args, kwargs)
      end

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

      def next_sequence
        @sequence_counter = (@sequence_counter || 0) + 1
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

        if kwargs.empty?
          case arity
          when 0
            callback.call
          else
            callback.call(result)
          end
        else
          callback.call(result, **kwargs)
        end
      rescue StandardError => e
        raise if @strict_mode

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

        raise error
      end
    end
  end
end
