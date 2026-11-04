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
    Binding = Struct.new(:keys, :model, :captures, :defaults, keyword_init: true) do
      def matches?(node)
        node.is_a?(Hash) && node.keys.sort == keys.sort
      end

      def model_class
        model.is_a?(Class) ? model : model.call
      end
    end

    # Build an inflater from the model-bindings table a PARG artifact
    # embeds (`parsanol parg bindings` dumps the same table).
    #
    # @param table [Hash, nil] `{"version"=>1, "rules"=>{name=>rule}}`; nil = no bindings
    # @param models [#call] resolves a model name to its class, lazily
    def self.from_table(table, models:)
      rules = table ? table.fetch('rules') : {}
      version = table && table['version']
      raise ArgumentError, "unsupported model_bindings version #{version.inspect}" if table && version != 1

      new(bindings: rules.values.map { |rule| binding_from_rule(rule, models) })
    end

    def self.binding_from_rule(rule, models)
      name = rule.fetch('model')
      # Both attribute => capture maps feed the same recursive inflation:
      # `children` merely names the attributes that hold nested nodes.
      captures = rule.fetch('captures', {}).merge(rule.fetch('children', {}))
      Binding.new(
        keys: rule.fetch('keys').map(&:to_sym),
        model: -> { models.call(name) },
        captures: captures.to_h { |attribute, key| [attribute.to_sym, key.to_sym] },
        defaults: rule.fetch('defaults', {}).transform_keys(&:to_sym)
      )
    end
    private_class_method :binding_from_rule

    def initialize(bindings:)
      @bindings = bindings
    end

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
      binding.model_class.new(**attributes)
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
