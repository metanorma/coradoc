# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Mixin for adding validation capabilities to model classes
      #
      # Provides a declarative way to define validation rules and
      # execute them to ensure model objects are in a valid state.
      #
      # Note: This is separate from Lutaml's type validation which happens
      # during initialization. This mixin is for business logic validation.
      #
      # @example Include in a model
      #   class Section
      #     include Coradoc::AsciiDoc::Model::Validatable
      #
      #     attribute :level, :integer
      #
      #     def validation_rules
      #       [
      #         ->(model, errors) {
      #           if model.level && (model.level < 1 || model.level > 6)
      #             errors << "level must be between 1 and 6"
      #           end
      #         }
      #       ]
      #     end
      #   end
      #
      # @example Validate an object
      #   section = Section.new(level: 7)
      #   section.valid? # => false
      #   section.validate_model! # raises ValidationError
      #
      module Validatable
        # Validate the model and raise an exception if invalid
        #
        # Note: Named validate_model! to avoid conflict with Lutaml's validate method
        # which is used for type checking during initialization.
        #
        # @raise [Coradoc::ValidationError] if validation fails
        # @return [true] if validation passes
        #
        # @example
        #   section.validate_model!
        def validate_model!
          errors = validation_errors

          return true if errors.empty?

          # Raise with the first error for backward compatibility
          raise Coradoc::ValidationError.new(
            self.class,
            errors.first[:attribute],
            errors.first[:message],
            errors.first[:value]
          )
        end

        # Check if the model is valid without raising
        #
        # @return [Boolean] true if valid, false otherwise
        #
        # @example
        #   if section.valid?
        #     # proceed with operation
        #   end
        def valid?
          validation_errors.empty?
        end

        # Get all validation errors
        #
        # @return [Array<Hash>] Array of error hashes with :attribute, :message, :value keys
        #
        # @example
        #   errors = model.validation_errors
        #   errors.each do |error|
        #     puts "#{error[:attribute]}: #{error[:message]}"
        #   end
        def validation_errors
          errors = []

          # Run validation rules if defined
          if respond_to?(:validation_rules, true)
            rules = validation_rules
            Array(rules).each do |rule|
              rule.call(self, errors)
            end
          end

          errors
        end

        # Validation rules to be defined by including class
        #
        # Should return an array of procs that accept (model, errors)
        # Each proc should add error hashes to the errors array when validation fails.
        #
        # @return [Array<Proc>] Array of validation rule procs
        #
        # @example Define validation rules
        #   def validation_rules
        #     [
        #       ->(model, errors) {
        #         if model.level.nil?
        #           errors << { attribute: :level, message: "is required", value: nil }
        #         end
        #       },
        #       ->(model, errors) {
        #         if model.level && (model.level < 1 || model.level > 6)
        #           errors << { attribute: :level, message: "must be between 1 and 6", value: model.level }
        #         end
        #       }
        #     ]
        #   end
        def validation_rules
          # Override in subclasses to define validation rules
          []
        end

        # Class methods to include when Validatable is included
        #
        module ClassMethods
          # Define a validation rule using a declarative syntax
          #
          # @param attribute [Symbol] The attribute to validate
          # @param options [Hash] Validation options
          # @option options [Proc] :validate Custom validation proc
          # @option options [Range] :in Valid range
          # @option options [Regexp] :format Valid format
          # @option options [TrueClass, FalseClass] :required Whether attribute is required
          # @option options [Numeric] :minimum Minimum value
          # @option options [Numeric] :maximum Maximum value
          #
          # @example Define validation
          #   validates :level, in: 1..6
          #   validates :title, required: true
          #   validates :email, format: /\A[^@]+@[^@]+\z/
          #
          def validates(attribute, options = {})
            validation_definitions[attribute] = options
          end

          # Get all validation definitions for this class
          #
          # @return [Hash] Attribute => options hash
          def validation_definitions
            @validation_definitions ||= {}
          end

          # Inherit validation definitions from parent class
          #
          # @param subclass [Class] The subclass
          def inherited(subclass)
            super
            subclass.instance_variable_set(:@validation_definitions,
                                           validation_definitions.dup)
          end
        end

        # Hook to extend class methods when included
        #
        # @param base [Class] The including class
        def self.included(base)
          base.extend(ClassMethods)
        end
      end
    end
  end
end
