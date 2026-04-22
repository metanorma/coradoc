# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Attribute list for AsciiDoc elements.
      #
      # Attribute lists represent the square-bracket attribute syntax in AsciiDoc:
      # [positional1, pos2, name1=value1, name2=value2]
      #
      # This class manages both positional and named attributes, with support
      # for validation and rejection of invalid values.
      #
      # @!attribute [r] positional
      #   @return [Array<Coradoc::AsciiDoc::Model::AttributeListAttribute>] Positional attributes (by position)
      #
      # @!attribute [r] named
      #   @return [Array<Coradoc::AsciiDoc::Model::NamedAttribute>] Named attributes (key-value pairs)
      #
      # @!attribute [r] rejected_positional
      #   @return [Array<Coradoc::AsciiDoc::Model::RejectedPositionalAttribute>] Rejected positional attributes
      #
      # @!attribute [r] rejected_named
      #   @return [Array<Coradoc::AsciiDoc::Model::NamedAttribute>] Rejected named attributes
      #
      # @example Create an attribute list
      #   attrs = Coradoc::AsciiDoc::Model::Coradoc::AsciiDoc::Model::AttributeList.new
      #   attrs.add_positional("value1")
      #   attrs.add_named("option", "value")
      #   attrs.to_adoc # => "[value1,option=value]\n"
      #
      # @example Empty attribute list
      #   attrs = Coradoc::AsciiDoc::Model::Coradoc::AsciiDoc::Model::AttributeList.new
      #   attrs.to_adoc # => "[]"
      #
      # @example Hide empty attribute list
      #   attrs = Coradoc::AsciiDoc::Model::Coradoc::AsciiDoc::Model::AttributeList.new
      #   attrs.to_adoc(show_empty: false) # => ""
      #
      class AttributeList < Base
        # Autoload Matchers module
        autoload :Matchers, 'coradoc/asciidoc/model/attribute_list/matchers'

        # Include Matchers module for validation methods
        include Matchers

        attribute :positional,
                  Coradoc::AsciiDoc::Model::AttributeListAttribute,
                  collection: true,
                  initialize_empty: true
        attribute :named, Coradoc::AsciiDoc::Model::NamedAttribute, collection: true, initialize_empty: true
        attribute :rejected_positional,
                  Coradoc::AsciiDoc::Model::RejectedPositionalAttribute,
                  collection: true,
                  initialize_empty: true
        attribute :rejected_named,
                  Coradoc::AsciiDoc::Model::NamedAttribute,
                  collection: true,
                  initialize_empty: true

        # Add positional attributes to this list
        #
        # @param attr [Array<Object>] Values to add as positional attributes
        #
        # @example Adding positional attributes
        #   attrs.add_positional("value1", "value2")
        #
        def add_positional(*attr)
          attr.each do |a|
            @positional << AttributeListAttribute.new(value: a)
          end
        end

        # Add a named attribute to this list
        #
        # @param name [String, Symbol] The attribute name
        # @param value [Object] The attribute value (will be converted to array)
        #
        # @example Adding named attributes
        #   attrs.add_named("title", "My Title")
        #   attrs.add_named("cols", "3,2,1")
        #
        def add_named(name, value)
          @named << NamedAttribute.new(
            name:,
            value: value.is_a?(Array) ? value : [value]
          )
        end

        # Validate named attributes against validators
        #
        # @param validators [Hash] Hash of name => matcher pairs
        # @yield [name, value] Block called for each invalid attribute
        #
        # @example Validate with custom validator
        #   attrs.validate_named(title: /./) do |name, value|
        #     puts "Invalid #{name}: #{value}"
        #   end
        #
        def validate_named(validators: {})
          named.each_with_index do |named_attribute, _i|
            name = named_attribute.name.to_sym
            value = named_attribute.value

            matcher = validators[name]

            next if matcher && matcher === value

            # Previous implementation would remove the value from the list
            # named.delete(name)
            rejected_named << named_attribute.dup
            yield(name, value) if block_given?
          end
        end

        # Validate positional attributes against validators
        #
        # @param validators [Array] Array of [position, matcher] pairs
        # @yield [position, value] Block called for each invalid attribute
        #
        # @example Validate positional attributes
        #   attrs.validate_positional([[0, /./], [1, Integer]])
        #
        def validate_positional(validators: [])
          positional.each_with_index do |positional_attribute, i|
            matcher = validators[i][1]
            value = positional_attribute.value

            next unless matcher && !(matcher === value)

            warn "#{value} does not match #{matcher}"
            # Previous implementation would remove the value from the list
            # positional[i] = nil
            rejected_positional << RejectedPositionalAttribute.new(
              position: i, value:
            )
            yield(i, value) if block_given?
          end
        end

        # To be overridden in subclasses.
        # @return [Array] Array of positional validators
        def positional_validators
          []
        end

        # To be overridden in subclasses.
        # @return [Hash] Hash of named validators
        def named_validators
          {}
        end

        # Validate this attribute list
        #
        # @return [Array<Lutaml::Model::Error>] Validation errors (empty if valid)
        def validate
          errors = super

          validate_positional(positional_validators) do |i, value|
            errors << Lutaml::Model::Error.new(
              "Positional attribute at position #{i} with value '#{value}' is not valid"
            )
          end

          validate_named(named_validators) do |name, value|
            errors << Lutaml::Model::Error.new(
              "Named attribute #{name} with value '#{value}' is not valid"
            )
          end

          errors
        end

        # Serialize this attribute list to AsciiDoc
        #
        # Generates the square-bracket syntax with valid attributes only.
        #
        # @param show_empty [Boolean] If true, show "[]" for empty lists (default: true)
        # @return [String] AsciiDoc representation of this attribute list
        #
        # @example Serialize with options
        #   attrs.to_adoc(show_empty: true)  # => "[value1,name=val]"
        #   attrs.to_adoc(show_empty: false) # => "[value1,name=val]"
        #   empty.to_adoc                     # => "[]"
        #   empty.to_adoc(show_empty: false) # => ""
        #
        def to_adoc(show_empty: true)
          valid_positional = positional.reject.with_index do |_p, i|
            rejected_positional.any? { |r| r.position == i }
          end

          valid_named = named.reject do |n|
            rejected_named.any? { |r| r.name == n.name }
          end

          adoc = [valid_positional,
                  valid_named].flatten.map(&:to_adoc).join(',')

          if adoc.empty? && show_empty
            '[]'
          elsif adoc.empty?
            ''
          else
            "[#{adoc}]"
          end
        end

        def empty?
          positional.empty? && named.empty?
        end

        # Get a named attribute value by name
        # @param name [String, Symbol] The attribute name
        # @return [Object, nil] The attribute value or nil if not found
        def [](name)
          name_str = name.to_s
          named.find { |n| n.name.to_s == name_str }&.value
        end

        # Get a named attribute value with default
        # @param name [String, Symbol] The attribute name
        # @param default [Object] The default value if not found
        # @return [Object] The attribute value or default
        def fetch(name, default = nil)
          self[name] || default
        end
      end
    end
  end
end
