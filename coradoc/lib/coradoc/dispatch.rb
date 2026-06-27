# frozen_string_literal: true

module Coradoc
  # Type-keyed handler dispatch.
  #
  # Replaces the bespoke `register/lookup` hashes that recur across gems with
  # one cohesive registry. Each gem that needs type-keyed dispatch configures
  # a single Dispatch instance and exposes its legacy DSL as thin delegates.
  #
  # Two resolution policies cover the common shapes:
  #
  # - `Coradoc::Dispatch.strict`     — exact key match, raises on miss
  # - `Coradoc::Dispatch.hierarchical` — walks ancestors on miss, returns nil
  #
  # Registries that need priority ordering, predicate matching, or lazy
  # loading do not fit this shape and stay as they are; the friction there is
  # genuine semantic difference, not duplicated mechanism.
  class Dispatch
    TERMINAL_ANCESTORS = [Object, BasicObject].freeze
    private_constant :TERMINAL_ANCESTORS

    class << self
      # Exact key match; raises if no entry. Used by registries that map a
      # concrete type to its sole handler (e.g. AsciiDoc ElementRegistry).
      def strict = new(walk_ancestors: false)

      # Walks the key's class ancestors on miss; returns nil if no entry.
      # Used by registries that want base-class handlers to apply to all
      # subclasses (e.g. Mirror HandlerRegistry).
      def hierarchical = new(walk_ancestors: true, miss: :return_nil)
    end

    def initialize(walk_ancestors: false, miss: :raise, &default)
      @walk_ancestors = walk_ancestors
      @miss = miss
      @default = default
      @entries = {}
    end

    def register(key, handler)
      @entries[key] = handler
    end

    # Replace the handler for an existing key. Returns the previous handler
    # so wrappers can chain: original = dispatch.override(K, Wrapper.new(original))
    def override(key, handler)
      previous = @entries[key]
      @entries[key] = handler
      previous
    end

    def unregister(key)
      @entries.delete(key)
    end

    # Resolve the handler for a key. Returns nil if no handler matches
    # unless the dispatch is configured to raise.
    def lookup(key)
      exact = @entries[key]
      return exact if exact
      return walk(key) if @walk_ancestors && key.is_a?(Class)

      apply_default(key)
    end

    # Resolve the handler, raising Coradoc::Error on miss.
    def lookup!(key)
      lookup(key) || raise(Coradoc::Error, "no handler registered for #{key.inspect}")
    end

    def registered?(key) = @entries.key?(key)

    def registered_keys = @entries.keys

    def clear! = @entries.clear

    private

    def walk(klass)
      klass.ancestors.each do |ancestor|
        next if ancestor == klass
        break if TERMINAL_ANCESTORS.include?(ancestor)

        entry = @entries[ancestor]
        return entry if entry
      end
      apply_default(klass)
    end

    def apply_default(key)
      return @default.call(key) if @default
      nil
    end
  end
end
