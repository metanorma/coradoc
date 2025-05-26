# frozen_string_literal: true

require_relative "attribute_list/matchers"

module Coradoc
  module Model
    class AttributeList < Base
      attribute :positional,
                AttributeListAttribute,
                collection: true,
                initialize_empty: true
      attribute :named, NamedAttribute, collection: true, initialize_empty: true
      attribute :rejected_positional,
                RejectedPositionalAttribute,
                collection: true,
                initialize_empty: true
      attribute :rejected_named,
                NamedAttribute,
                collection: true,
                initialize_empty: true

      asciidoc do
        map_attribute "positional", to: :positional
        map_attribute "named", to: :named
        map_attribute "rejected_positional", to: :rejected_positional
        map_attribute "rejected_named", to: :rejected_named
      end

      def add_positional(*attr)
        attr.each do |a|
          @positional << AttributeListAttribute.new(value: a)
        end
      end

      def add_named(name, value)
        @named << NamedAttribute.new(
          name:,
          value: value.is_a?(Array) ? value : [value],
        )
      end

      def validate_named(validators: {})
        named.each_with_index do |named_attribute, _i|
          name = named_attribute.name.to_sym
          value = named_attribute.value

          matcher = validators[name]

          unless matcher && matcher === value
            # Previous implementation would remove the value from the list
            # named.delete(name)
            rejected_named << named_attribute.dup
            yield(name, value) if block_given?
          end
        end
      end

      def validate_positional(validators: [])
        positional.each_with_index do |positional_attribute, i|
          matcher = validators[i][1]
          value = positional_attribute.value

          if matcher && !(matcher === value)
            warn "#{value} does not match #{matcher}"
            # Previous implementation would remove the value from the list
            # positional[i] = nil
            rejected_positional << RejectedPositionalAttribute.new(
              position: i, value:,
            )
            yield(i, value) if block_given?
          end
        end
      end

      # To be overridden.
      def positional_validators
        []
      end

      # To be overridden.
      def named_validators
        {}
      end

      def validate
        errors = super

        validate_positional(positional_validators) do |i, value|
          errors << Lutaml::Model::Error.new(
            "Positional attribute at position #{i} with value '#{value}' is not valid",
          )
        end

        validate_named(named_validators) do |name, value|
          errors << Lutaml::Model::Error.new(
            "Named attribute #{name} with value '#{value}' is not valid",
          )
        end

        errors
      end

      def to_asciidoc(show_empty: true)
        valid_positional = positional.reject.with_index { |_p, i|
          rejected_positional.any? { |r| r.position == i }
        }

        valid_named = named.reject { |n|
          rejected_named.any? { |r| r.name == n.name }
        }

        adoc = [valid_positional,
                valid_named].flatten.map(&:to_asciidoc).join(",")

        puts "pp adoc"
        pp adoc
        if adoc.empty? && show_empty
          "[]"
        elsif adoc.empty?
          ""
        else
          "[#{adoc}]"
        end
      end

      def empty?
        positional.empty? && named.empty?
      end
    end
  end
end
