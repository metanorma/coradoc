# frozen_string_literal: true

module Coradoc
  # Document validation framework for schema-based validation.
  #
  # This module provides a flexible validation framework for ensuring
  # documents conform to expected structures and rules.
  #
  # @example Creating a validation schema
  #   schema = Coradoc::Validation::Schema.define do
  #     required :title, type: String, min_length: 1
  #     required :sections, type: Array, min_count: 1
  #     optional :author, type: String
  #
  #     rule :check_references do |doc|
  #       refs = doc.query('xref')
  #       missing = refs.reject { |r| doc.resolve_reference(r) }
  #       missing.map { |r| "Unresolved reference: #{r.target}" }
  #     end
  #   end
  #
  # @example Validating a document
  #   result = schema.validate(document)
  #   if result.valid?
  #     puts "Document is valid"
  #   else
  #     result.errors.each { |e| puts e.message }
  #   end
  #
  module Validation
    # A single validation error
    class Error
      attr_reader :path, :message, :code, :element

      # Create a validation error
      #
      # @param message [String] Error message
      # @param path [String, nil] Path to the error location
      # @param code [Symbol, nil] Error code for programmatic handling
      # @param element [Object, nil] The element that failed validation
      def initialize(message, path: nil, code: nil, element: nil)
        @message = message
        @path = path
        @code = code
        @element = element
      end

      # Format error as string
      #
      # @return [String]
      def to_s
        if path
          "#{path}: #{message}"
        else
          message
        end
      end

      # Convert to hash
      #
      # @return [Hash]
      def to_h
        { message: message, path: path, code: code }
      end
    end

    # Validation result containing errors
    class Result
      attr_reader :errors, :warnings

      # Create a validation result
      #
      # @param errors [Array<Error>] Validation errors
      # @param warnings [Array<Error>] Validation warnings
      def initialize(errors: [], warnings: [])
        @errors = Array(errors)
        @warnings = Array(warnings)
      end

      # Check if validation passed
      #
      # @return [Boolean]
      def valid?
        @errors.empty?
      end

      # Check if there are any warnings
      #
      # @return [Boolean]
      def warnings?
        @warnings.any?
      end

      # Get error count
      #
      # @return [Integer]
      def error_count
        @errors.size
      end

      # Get warning count
      #
      # @return [Integer]
      def warning_count
        @warnings.size
      end

      # Add an error
      #
      # @param message [String] Error message
      # @param path [String, nil] Error path
      # @param code [Symbol, nil] Error code
      # @param element [Object, nil] Failed element
      # @return [Error] The added error
      def add_error(message, path: nil, code: nil, element: nil)
        error = Error.new(message, path: path, code: code, element: element)
        @errors << error
        error
      end

      # Add a warning
      #
      # @param message [String] Warning message
      # @param path [String, nil] Warning path
      # @param code [Symbol, nil] Warning code
      # @param element [Object, nil] Related element
      # @return [Error] The added warning
      def add_warning(message, path: nil, code: nil, element: nil)
        warning = Error.new(message, path: path, code: code, element: element)
        @warnings << warning
        warning
      end

      # Merge another result into this one
      #
      # @param other [Result] Another validation result
      # @return [void]
      def merge!(other)
        @errors.concat(other.errors)
        @warnings.concat(other.warnings)
      end

      # Get errors for a specific path
      #
      # @param path [String] The path to filter by
      # @return [Array<Error>]
      def errors_at(path)
        @errors.select { |e| e.path == path }
      end

      # Convert to hash
      #
      # @return [Hash]
      def to_h
        {
          valid: valid?,
          error_count: error_count,
          warning_count: warning_count,
          errors: @errors.map(&:to_h),
          warnings: @warnings.map(&:to_h)
        }
      end
    end

    # Base class for validation rules
    class Rule
      attr_reader :name, :options

      # Create a validation rule
      #
      # @param name [Symbol] Rule name
      # @param options [Hash] Rule options
      def initialize(name, **options)
        @name = name
        @options = options
      end

      # Validate an element
      #
      # @param element [Object] Element to validate
      # @param context [Hash] Validation context
      # @return [Array<String>] Error messages
      def validate(element, context = {})
        raise NotImplementedError, 'Subclasses must implement #validate'
      end
    end

    # Built-in validation rules
    module Rules
      # Required field validation
      class Required < Rule
        def validate(element, _context = {})
          field = options[:field]
          value = get_value(element, field)

          return [] unless value.nil?

          ["#{field} is required"]
        end

        private

        def get_value(element, field)
          element.send(field) if element.respond_to?(field)
        end
      end

      # Type validation
      class Type < Rule
        def validate(element, _context = {})
          field = options[:field]
          expected_type = options[:type]
          value = element.send(field) if element.respond_to?(field)

          return [] if value.nil? && !options[:required]
          return [] if value.nil?

          return ["#{field} must be #{expected_type.name}, got #{value.class.name}"] unless value.is_a?(expected_type)

          []
        end
      end

      # Length validation
      class Length < Rule
        def validate(element, _context = {})
          field = options[:field]
          value = element.send(field) if element.respond_to?(field)

          return [] if value.nil?

          errors = []
          length = value.respond_to?(:length) ? value.length : 0

          if options[:min] && length < options[:min]
            errors << "#{field} must have at least #{options[:min]} characters/items"
          end

          if options[:max] && length > options[:max]
            errors << "#{field} must have at most #{options[:max]} characters/items"
          end

          errors
        end
      end

      # Count validation for arrays/collections
      class Count < Rule
        def validate(element, _context = {})
          field = options[:field]
          value = element.send(field) if element.respond_to?(field)

          return [] if value.nil?

          errors = []
          count = value.respond_to?(:count) ? value.count : 0

          errors << "#{field} must have at least #{options[:min]} items" if options[:min] && count < options[:min]

          errors << "#{field} must have at most #{options[:max]} items" if options[:max] && count > options[:max]

          errors
        end
      end

      # Format validation with regex
      class Format < Rule
        def validate(element, _context = {})
          field = options[:field]
          pattern = options[:pattern]
          value = element.send(field) if element.respond_to?(field)

          return [] if value.nil?

          return ["#{field} has invalid format"] unless pattern.match?(value.to_s)

          []
        end
      end

      # Custom block validation
      class Custom < Rule
        def validate(element, context = {})
          block = options[:block]
          return [] unless block

          result = block.call(element, context)
          Array(result)
        end
      end
    end

    # Validation schema definition
    class Schema
      attr_reader :fields, :rules

      # Define a new schema
      #
      # @yield Block for schema definition
      # @return [Schema] The defined schema
      def self.define(&block)
        schema = new
        schema.instance_eval(&block) if block
        schema
      end

      def initialize
        @fields = {}
        @rules = []
      end

      # Define a required field
      #
      # @param name [Symbol] Field name
      # @param type [Class, nil] Expected type
      # @param options [Hash] Additional options
      # @return [void]
      def required(name, type: nil, **options)
        @fields[name] = { required: true, type: type, **options }
      end

      # Define an optional field
      #
      # @param name [Symbol] Field name
      # @param type [Class, nil] Expected type
      # @param options [Hash] Additional options
      # @return [void]
      def optional(name, type: nil, **options)
        @fields[name] = { required: false, type: type, **options }
      end

      # Add a custom validation rule
      #
      # @param name [Symbol] Rule name
      # @yield Block for validation
      # @return [void]
      def rule(name, &block)
        @rules << Rules::Custom.new(name, block: block)
      end

      # Add a pre-built rule
      #
      # @param rule [Rule] The rule to add
      # @return [void]
      def add_rule(rule)
        @rules << rule
      end

      # Validate a document
      #
      # @param document [Object] Document to validate
      # @return [Result] Validation result
      def validate(document)
        result = Result.new

        # Validate fields
        @fields.each do |name, config|
          validate_field(document, name, config, result)
        end

        # Run custom rules
        @rules.each do |rule|
          errors = rule.validate(document, schema: self)
          errors.each { |e| result.add_error(e, code: rule.name) }
        end

        result
      end

      private

      def validate_field(document, name, config, result)
        value = document.respond_to?(name) ? document.send(name) : nil
        path = name.to_s

        # Check required
        if config[:required] && value.nil?
          result.add_error("#{name} is required", path: path, code: :required)
          return
        end

        return if value.nil?

        # Check type
        if config[:type] && !value.is_a?(config[:type])
          result.add_error(
            "#{name} must be #{config[:type].name}, got #{value.class.name}",
            path: path,
            code: :type
          )
        end

        # Check min_length
        if config[:min_length] && value.respond_to?(:length) && (value.length < config[:min_length])
          result.add_error(
            "#{name} must have at least #{config[:min_length]} characters",
            path: path,
            code: :min_length
          )
        end

        # Check max_length
        if config[:max_length] && value.respond_to?(:length) && (value.length > config[:max_length])
          result.add_error(
            "#{name} must have at most #{config[:max_length]} characters",
            path: path,
            code: :max_length
          )
        end

        # Check min_count
        if config[:min_count] && value.respond_to?(:count) && (value.count < config[:min_count])
          result.add_error(
            "#{name} must have at least #{config[:min_count]} items",
            path: path,
            code: :min_count
          )
        end

        # Check format
        return unless config[:format].is_a?(Regexp) && !config[:format].match?(value.to_s)

        result.add_error(
          "#{name} has invalid format",
          path: path,
          code: :format
        )
      end
    end

    # Schema generator from CoreModel types
    #
    # Automatically generates validation schemas from Lutaml::Model classes.
    # This enables automatic validation based on model structure.
    #
    # @example Generate schema from CoreModel class
    #   schema = Coradoc::Validation::SchemaGenerator.generate(Coradoc::CoreModel::StructuralElement)
    #   result = schema.validate(document)
    #
    # @example Customize generated schema
    #   schema = Coradoc::Validation::SchemaGenerator.generate(
    #     Coradoc::CoreModel::Block,
    #     required: [:content],
    #     ignored: [:metadata]
    #   )
    #
    class SchemaGenerator
      class << self
        # Generate a validation schema from a CoreModel class
        #
        # @param model_class [Class] The CoreModel class to generate schema from
        # @param required [Array<Symbol>] Attributes to mark as required
        # @param ignored [Array<Symbol>] Attributes to skip in schema
        # @param custom_rules [Hash] Additional validation rules per attribute
        # @return [Schema] Generated validation schema
        #
        # @example Basic generation
        #   schema = SchemaGenerator.generate(Coradoc::CoreModel::Block)
        #
        # @example With required fields
        #   schema = SchemaGenerator.generate(
        #     Coradoc::CoreModel::Block,
        #     required: [:content, :delimiter_type]
        #   )
        #
        # @example With custom rules
        #   schema = SchemaGenerator.generate(
        #     Coradoc::CoreModel::StructuralElement,
        #     custom_rules: {
        #       level: { min: 1, max: 6 }
        #     }
        #   )
        #
        def generate(model_class, required: [], ignored: [], custom_rules: {})
          return nil unless model_class.respond_to?(:attributes)

          # Pre-compute attribute definitions before the schema block
          attribute_defs = compute_attribute_definitions(
            model_class, required, ignored, custom_rules
          )

          Schema.define do
            attribute_defs.each do |name, type, options, is_required|
              if is_required
                required name, type: type, **options
              else
                optional name, type: type, **options
              end
            end
          end
        end

        # Map Lutaml::Model type to Ruby class
        #
        # @param type [Symbol, Class] The Lutaml::Model type
        # @return [Class, Array<Class>] Ruby class(es)
        def map_type(type)
          # Handle Lutaml::Model type classes by name
          type_name = type.to_s

          case type_name
          when 'Lutaml::Model::Type::String'
            String
          when 'Lutaml::Model::Type::Integer'
            Integer
          when 'Lutaml::Model::Type::Float'
            Float
          when 'Lutaml::Model::Type::Boolean'
            [TrueClass, FalseClass]
          when 'Lutaml::Model::Type::Date'
            Date
          when 'Lutaml::Model::Type::Time'
            Time
          when 'Lutaml::Model::Type::DateTime'
            Time
          when 'Lutaml::Model::Type::Hash'
            Hash
          when 'Lutaml::Model::Type::Array'
            Array
          else
            # For non-Lutaml types (like CoreModel::Base), return the type itself
            type.is_a?(Class) ? type : Object
          end
        end

        private

        # Compute attribute definitions for the schema
        #
        # @return [Array<Array>] Array of [name, type, options, required] tuples
        def compute_attribute_definitions(model_class, required, ignored, custom_rules)
          model_class.attributes.filter_map do |name, attr|
            next if ignored.include?(name)

            type = map_type(attr.type)
            options = build_options(attr, custom_rules[name])
            # By default, all fields are optional unless explicitly required
            is_required = required.include?(name)

            [name, type, options, is_required]
          end
        end

        # Check if attribute is a collection
        #
        # @param attr [Lutaml::Model::Attribute] The attribute
        # @return [Boolean]
        def collection?(attr)
          attr.options[:collection] == true
        end

        # Build validation options for an attribute
        #
        # @param attr [Lutaml::Model::Attribute] The attribute
        # @param custom [Hash, nil] Custom rules for this attribute
        # @return [Hash] Validation options
        def build_options(attr, custom = nil)
          options = {}

          # Add collection validation
          options[:min_count] = 0 if collection?(attr)

          # Merge custom rules
          options.merge!(custom) if custom

          options
        end
      end
    end

    # Module-level methods
    class << self
      # Define a validation schema
      #
      # @yield Schema definition block
      # @return [Schema] The defined schema
      def define(&block)
        Schema.define(&block)
      end

      # Generate a validation schema from a CoreModel class
      #
      # @param model_class [Class] The CoreModel class
      # @param options [Hash] Options passed to SchemaGenerator.generate
      # @return [Schema] Generated validation schema
      #
      # @example
      #   schema = Coradoc::Validation.auto_schema(Coradoc::CoreModel::Block)
      #   result = schema.validate(document)
      #
      def auto_schema(model_class, **options)
        SchemaGenerator.generate(model_class, **options)
      end

      # Validate a document with default schema
      #
      # @param document [Object] Document to validate
      # @return [Result] Validation result
      def validate(document)
        default_schema.validate(document)
      end

      # Get the default validation schema
      #
      # @return [Schema]
      def default_schema
        @default_schema ||= Schema.define do
          optional :id, type: String
          optional :title, type: String
        end
      end

      # Set the default validation schema
      #
      # @param schema [Schema] The schema to use
      # @return [void]
      attr_writer :default_schema
    end
  end
end
