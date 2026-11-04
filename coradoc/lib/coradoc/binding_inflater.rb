# frozen_string_literal: true

module Coradoc
  # Generic raw-tree to typed-model engine behind PARG bindings.
  #
  # A parser yields a raw tree of hashes (capture name => value). A
  # Binding says: a node with exactly these keys is an instance of this
  # model, its attributes assigned from these captures. The inflater
  # instantiates the bound model, recursing through captured
  # collections; everything unbound falls through to a residual (the
  # format's hand-written processing), so a format migrates one rule at
  # a time and nothing changes until a binding exists.
  #
  #   inflater = BindingInflater.new(bindings: [binding])
  #   inflater.inflate(node) { |unbound| legacy_transform(unbound) }
  class BindingInflater
    # One bound rule.
    #
    # @!attribute keys [Array<Symbol>] the exact capture-key set of a node
    # @!attribute model [Class, #call] the model class, or a callable that
    #   returns it (resolved on first use, for lazily loaded classes)
    # @!attribute captures [Hash{Symbol=>Symbol}] attribute => capture key
    # @!attribute defaults [Hash{Symbol=>Object}] attributes fixed by the rule
    # @!attribute via [#call, nil] optional named hook for a rule's semantic
    #   step: receives the assigned attributes, returns the attributes the
    #   model is built from. Pure capture-to-attribute rules need none.
    #   With `model: nil` the hook's return value IS the result (for rules
    #   that build a tree, pass a value through, or return plain data).
    # @!attribute raw [Hash{Symbol=>Symbol}] attribute => capture key, assigned
    #   as captured: never inflated and never sent to the residual. For hooks
    #   that read the raw subtree themselves.
    Binding = Struct.new(:keys, :model, :captures, :defaults, :via, :raw, keyword_init: true) do
      def matches?(node)
        node.is_a?(Hash) && node.keys.sort == keys.sort
      end

      def model_class
        model.is_a?(Class) || model.nil? ? model : model.call
      end
    end

    def initialize(bindings:)
      @bindings = bindings
    end

    # @return [Array<Binding>] the bindings, for callers that need to know
    #   which rules are bound (e.g. a corpus guard)
    attr_reader :bindings

    def bound?(node)
      !binding_for(node).nil?
    end

    # @param node [Object] a raw tree node
    # @yield [Object] an unbound node, handed to the residual
    # @return [Object] the model for a bound node, else the residual's result
    def inflate(node, &residual)
      binding = binding_for(node)
      return yield(node) unless binding

      attributes = binding.defaults.dup
      binding.captures.each { |attribute, key| attributes[attribute] = inflate_value(node[key], &residual) }
      binding.raw&.each { |attribute, key| attributes[attribute] = node[key] }
      attributes = binding.via.call(attributes) if binding.via
      binding.model ? binding.model_class.new(**attributes) : attributes
    end

    private

    def binding_for(node)
      @bindings.find { |binding| binding.matches?(node) }
    end

    def inflate_value(value, &residual)
      case value
      when Array then value.map { |item| inflate_value(item, &residual) }
      when Hash then inflate(value, &residual)
      else value.respond_to?(:to_str) ? value.to_str : value
      end
    end
  end
end
