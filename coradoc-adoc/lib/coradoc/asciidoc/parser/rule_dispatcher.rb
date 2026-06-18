# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      # Wraps every parser rule for Parslet memoization.
      #
      # Parameterized rules (e.g., `block_style(n_deep, delimiter, repeater)`)
      # cannot be memoized by Parslet directly because their result depends
      # on the args. This module aliases each rule to a per-args dispatch
      # rule so Parslet sees a memoizable, parameterless rule for every
      # (rule_name, args) combination. Parameterless rules get a single
      # memoized alias.
      #
      # Also warns when a parser method is defined in more than one parser
      # module — duplicate definitions are usually a refactoring mistake
      # and produce confusing "last one wins" behavior at include time.
      #
      # Invoked once at Parser::Base load time.
      module RuleDispatcher
        DISPATCH_CONFIG = {
          add_dispatch: true,
          with_params: true
        }.freeze

        class << self
          # @param parser_class [Class] Parser::Base or a subclass
          def apply(parser_class)
            parser_methods = collect_rule_names
            warn_on_duplicates(parser_methods)
            wrap_rules(parser_class, parser_methods)
          end

          # Per-instance dispatch invoked from the parameterized rule wrappers.
          # @param parser_instance [Parser::Base]
          # @param alias_name [Symbol] The alias created at wrap time
          # @param args [Array]
          # @param kwargs [Hash]
          def dispatch(parser_instance, alias_name, *args, **kwargs)
            cache = dispatch_cache(parser_instance)
            key = dispatch_key(alias_name, args, kwargs)
            unless cache.key?(key)
              rule_name = dispatch_rule_name(alias_name, key)
              unless parser_instance.respond_to?(rule_name)
                build_dispatch_rule(parser_instance.class, alias_name,
                                    rule_name, args, kwargs)
              end
              cache[key] = rule_name
            end
            parser_instance.public_send(cache[key])
          end

          private

          # Walk every parser module and collect rule-method names.
          # `instance_methods(false)` returns only methods defined in the
          # module itself, not inherited ones — without `false` we would
          # also wrap Object#send, Kernel#__send__, Module#class, etc.
          # Wrapping `__send__` in particular causes infinite recursion.
          # @return [Hash{Symbol => Array<Module>}]
          def collect_rule_names
            parser_constants = Parser.constants - %i[Base Cache FixFiles RuleDispatcher]
            parser_constants.each_with_object({}) do |const, acc|
              Parser.const_get(const).instance_methods(false).each do |name|
                acc[name] ||= []
                acc[name] << const
              end
            end
          end

          def warn_on_duplicates(parser_methods)
            parser_methods.each do |name, sites|
              next unless sites.size > 1

              modules = sites.map { |c| Parser.const_get(c) }
              Coradoc::Logger.warn(
                "Parser method '#{name}' is defined #{sites.size} times in #{modules.join(', ')}"
              )
            end
          end

          def wrap_rules(parser_class, parser_methods)
            parser_methods.each_key do |rule_name|
              params = parser_class.instance_method(rule_name).parameters
              if dispatch? && params.empty?
                wrap_nondispatch(parser_class, rule_name)
              elsif dispatch? && with_params?
                wrap_dispatch(parser_class, rule_name)
              end
            end
          end

          def wrap_nondispatch(parser_class, rule_name)
            alias_name = :"alias_nondispatch_#{rule_name}"
            guard_name = :"alias_nondispatch_rule_guard_#{rule_name}"
            return if parser_class.method_defined?(guard_name)

            parser_class.class_eval do
              alias_method alias_name, rule_name
              define_method(guard_name) {}
              rule(rule_name) do
                public_send(alias_name)
              end
            end
          end

          def wrap_dispatch(parser_class, rule_name)
            alias_name = :"alias_dispatch_#{rule_name}"
            guard_name = :"alias_dispatch_rule_guard_#{rule_name}"
            return if parser_class.method_defined?(guard_name)

            parser_class.class_eval do
              alias_method alias_name, rule_name
              define_method(guard_name) {}
              define_method(rule_name) do |*args, **kwargs|
                RuleDispatcher.dispatch(self, alias_name, *args, **kwargs)
              end
            end
          end

          def dispatch_cache(parser_instance)
            parser_instance.instance_variable_get(:@_rule_dispatch_cache) ||
              parser_instance.instance_variable_set(:@_rule_dispatch_cache, {})
          end

          def dispatch?
            DISPATCH_CONFIG[:add_dispatch]
          end

          def with_params?
            DISPATCH_CONFIG[:with_params]
          end

          def dispatch_key(alias_name, args, kwargs)
            [alias_name, args, kwargs.to_a.sort].hash.abs
          end

          def dispatch_rule_name(alias_name, key)
            :"#{alias_name}_#{key}"
          end

          # Build a Parslet memoizable rule that closes over the captured
          # args and forwards to the original aliased rule. Using Parslet's
          # class-level `rule()` (not define_method on singleton_class) is
          # essential — Parslet's memoization, `as()`, and tree building
          # depend on the rule going through the standard Parslet machinery.
          def build_dispatch_rule(parser_class, original_alias, rule_name, args, kwargs)
            parser_class.class_eval do
              rule(rule_name) do
                public_send(original_alias, *args, **kwargs)
              end
            end
          end
        end
      end
    end
  end
end
