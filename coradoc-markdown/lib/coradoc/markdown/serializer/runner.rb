# frozen_string_literal: true

require_relative 'context'

module Coradoc
  module Markdown
    class Serializer
      # Stateful runner: holds a frozen Config + Registry, exposes `#call`.
      # Each top-level `call` creates a fresh Context (per-document mutable
      # state) so the same runner can serialize multiple documents without
      # cross-document leakage.
      class Runner
        attr_reader :config, :registry

        def initialize(config:, registry:)
          @config = config
          @registry = registry
        end

        def call(element)
          ctx = Context.new(config: config, registry: registry, runner: self)
          result = serialize(element, ctx)
          result = append_link_refs(result, ctx)
          append_footnote_defs(result, ctx).to_s
        end

        def serialize(element, ctx = nil)
          ctx ||= Context.new(config: config, registry: registry, runner: self)
          case element
          when String
            element
          when nil
            ''
          when Array
            element.map { |e| serialize(e, ctx) }.join
          else
            serializer = registry.lookup(element)
            if serializer
              serializer.call(element, ctx)
            else
              raise ArgumentError,
                    "Unknown element type for serialization: #{element.class}. " \
                      'Expected a known Markdown model type.'
            end
          end
        end

        def serialize_inline(element, ctx)
          case element
          when String
            element
          when nil
            ''
          when ::Coradoc::Markdown::Base, ::Coradoc::Markdown::Document
            serialize(element, ctx)
          when Array
            element.map { |e| serialize_inline(e, ctx) }.join
          else
            raise ArgumentError,
                  "Cannot serialize inline content of type #{element.class}. " \
                  'Expected String, known inline model, or Base subclass.'
          end
        end

        private

        def append_link_refs(result, ctx)
          return result if ctx.link_refs.empty?

          refs = ctx.link_refs.map do |ref|
            "[#{ref.id}]: #{ref.url}#{ref.title ? " \"#{ref.title}\"" : ''}"
          end.join("\n")
          "#{result}\n\n#{refs}"
        end

        def append_footnote_defs(result, ctx)
          return result if ctx.footnote_defs.empty?

          "#{result}\n\n#{ctx.footnote_defs.join("\n")}"
        end
      end
    end
  end
end
