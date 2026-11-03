# frozen_string_literal: true

module Coradoc
  module Lint
    # Parameterized invariant templates (#309).
    #
    # An invariant is declared ONCE as an operator over references
    # (lambdas); each format BINDS its own model paths into the
    # operator. Semantics are shared, bindings are per-format — the
    # formats keep their own model sets (hub-and-spoke).
    #
    #   Coradoc::Lint::Template.register(
    #     :monotonic, id: 'MD001', format: :markdown,
    #     roots: ->(doc) { headings(doc) },
    #     level: :level.to_proc, label: :text.to_proc, order: :sequence
    #   )
    #
    # Operators (smallest expressive set first):
    #
    #   :monotonic  levels may not skip downward (refs: roots, level,
    #               label; optional children, order, message)
    #   :unique     keys may not repeat (refs: roots, key, message;
    #               optional children)
    #   :present    subjects must satisfy a presence test (refs:
    #               subjects, present, message)
    module Template
      # Shared plumbing: ref validation and the check entry point.
      class Operator
        REQUIRED = [].freeze
        OPTIONAL = [].freeze
        # Optional refs that are plain values, not lambdas.
        CONFIG = [].freeze

        def initialize(**refs)
          unknown = refs.keys - self.class::REQUIRED - self.class::OPTIONAL
          raise ArgumentError, "unknown refs #{unknown.inspect} for #{self.class.name}" unless unknown.empty?

          missing = self.class::REQUIRED - refs.keys
          raise ArgumentError, "missing refs #{missing.inspect} for #{self.class.name}" unless missing.empty?

          bad = refs.reject { |name, value| self.class::CONFIG.include?(name) || value.respond_to?(:call) }
          raise ArgumentError, "refs #{bad.keys.inspect} must be callable" unless bad.empty?

          @refs = refs
        end

        # @return [Array<String>] one message per violation
        def messages(_document)
          raise NotImplementedError
        end

        private

        attr_reader :refs

        def ref(name, default = nil)
          refs.fetch(name, default)
        end

        # Depth-first node enumeration through the optional
        # children ref (none by default).
        def each_node(nodes, children, &block)
          Array(nodes).each do |node|
            yield(node)
            each_node(children.call(node), children, &block)
          end
        end
      end

      # Levels must not skip: a node may be at most one level deeper
      # than its predecessor — its enclosing node (order: :tree,
      # via children) or the previous node (order: :sequence).
      class Monotonic < Operator
        REQUIRED = %i[roots level label].freeze
        OPTIONAL = %i[children order message].freeze
        CONFIG = %i[order].freeze
        NO_CHILDREN = ->(_node) { [] }
        DEFAULT_MESSAGE = lambda do |from, to, label|
          "heading level skips from #{from} to #{to}: #{label}"
        end

        def initialize(**refs)
          super
          @order = refs.fetch(:order, :tree)
          return if %i[tree sequence].include?(@order)

          raise ArgumentError, "order must be :tree or :sequence, got #{@order.inspect}"
        end

        def messages(document)
          out = []
          nodes = ref(:roots).call(document)
          if @order == :sequence
            sequence(nodes, out)
          else
            walk(nodes, 0, out)
          end
          out
        end

        private

        def sequence(nodes, out)
          Array(nodes).each_cons(2) do |prev, node|
            check(ref(:level).call(prev), ref(:level).call(node), node, out)
          end
        end

        def walk(nodes, parent_level, out)
          Array(nodes).each do |node|
            level = ref(:level).call(node)
            check(parent_level, level, node, out)
            walk(ref(:children, NO_CHILDREN).call(node), level || parent_level, out)
          end
        end

        def check(from, to, node, out)
          return unless to && to > from + 1

          out << ref(:message, DEFAULT_MESSAGE).call(from, to, ref(:label).call(node))
        end
      end

      # Keys must not repeat. Nodes whose key is nil are ignored.
      class Unique < Operator
        REQUIRED = %i[roots key message].freeze
        OPTIONAL = %i[children].freeze

        def messages(document)
          counts = Hash.new(0)
          each_node(ref(:roots).call(document),
                    ref(:children, Monotonic::NO_CHILDREN)) do |node|
            key = ref(:key).call(node)
            counts[key] += 1 unless key.nil?
          end
          counts.select { |_key, count| count > 1 }
                .map { |key, count| ref(:message).call(key, count) }
        end
      end

      # Every subject must satisfy the presence test.
      class Present < Operator
        REQUIRED = %i[subjects present message].freeze

        def messages(document)
          Array(ref(:subjects).call(document))
            .reject { |subject| ref(:present).call(subject) }
            .map { |subject| ref(:message).call(subject) }
        end
      end

      OPERATORS = {
        monotonic: Monotonic,
        unique: Unique,
        present: Present
      }.freeze

      class << self
        # Bind a format's refs into an operator, yielding a Rule
        # subclass the existing Registry / Runner can use unchanged.
        #
        # @param operator [Symbol] one of OPERATORS
        # @return [Class<Rule>]
        def bind(operator, id:, format:, **refs)
          klass = OPERATORS.fetch(operator) do
            raise ArgumentError, "unknown template operator #{operator.inspect}"
          end
          evaluator = klass.new(**refs)

          Class.new(Rule) do
            rule_id id
            applies_to format
            define_method(:check) do |document, path|
              evaluator.messages(document).map do |message|
                build_violation(path: path, message: message)
              end
            end
          end
        end

        # Bind and register in the lint registry.
        def register(operator, registry: Coradoc::Lint.registry, **)
          rule = bind(operator, **)
          registry.register(rule)
          rule
        end
      end
    end
  end
end
