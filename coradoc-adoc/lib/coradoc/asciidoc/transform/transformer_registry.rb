# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      class TransformerRegistry
        class << self
          def registry
            @registry ||= {}
          end

          def register(source_class, transformer, target_class: nil)
            registry[source_class] = transformer

            return unless target_class

            reverse_registry[target_class] = transformer
          end

          def register_with_priority(source_class, transformer, priority: 0)
            @prioritized_registry ||= []
            @prioritized_registry << {
              class: source_class,
              transformer: transformer,
              priority: priority
            }
            @prioritized_registry.sort_by! { |e| -e[:priority] }
          end

          def lookup(model_class)
            return registry[model_class] if registry.key?(model_class)

            if @prioritized_registry
              entry = @prioritized_registry.find { |e| model_class <= e[:class] }
              return entry[:transformer] if entry
            end

            model_class.ancestors.each do |ancestor|
              next if ancestor == model_class
              next if [Object, BasicObject].include?(ancestor)

              return registry[ancestor] if registry.key?(ancestor)
            end

            nil
          end

          def transform(model)
            return model if model.nil?
            return model.map { |item| transform(item) } if model.is_a?(Array)

            transformer = lookup(model.class)
            transformer ? transformer.call(model) : model
          end

          def registered?(model_class)
            !lookup(model_class).nil?
          end

          def clear
            registry.clear
            @prioritized_registry = nil
          end

          def registered_classes
            registry.keys
          end

          private

          def reverse_registry
            @reverse_registry ||= {}
          end
        end
      end

      Registry = TransformerRegistry
    end
  end
end
