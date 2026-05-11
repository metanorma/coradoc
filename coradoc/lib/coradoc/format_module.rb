# frozen_string_literal: true

module Coradoc
  # Declared interface contract for format modules.
  #
  # Format modules registered via Coradoc.register_format must implement:
  #
  # Required:
  # - parse_to_core(input, options={}) → CoreModel::Base
  # - serialize(model, **options) → String
  #
  # Optional:
  # - parse(input, options={}) → format-specific model
  # - handles_model?(model) → Boolean
  # - to_core(model) → CoreModel::Base
  # - serialize? → Boolean
  #
  module FormatModule
    MINIMUM_PARSE_METHODS = %i[parse_to_core parse].freeze
    REQUIRED_METHODS = %i[serialize].freeze

    # Default implementations for optional format module methods.
    # Format modules are auto-extended with this during registration.
    module Interface
      def handles_model?(_model)
        false
      end

      def serialize?
        true
      end
    end

    # Validate that a format module implements the minimum interface.
    # Warns to $stderr if methods are missing. Returns true if valid.
    def self.validate!(format_module, format_name)
      has_parse = MINIMUM_PARSE_METHODS.any? { |m| format_module.public_methods.include?(m) }
      has_serialize = REQUIRED_METHODS.all? { |m| format_module.public_methods.include?(m) }

      return true if has_parse && has_serialize

      missing = []
      missing << 'parse_to_core or parse' unless has_parse
      missing << 'serialize' unless has_serialize
      warn "Coradoc: format :#{format_name} (#{format_module}) missing: #{missing.join(', ')}"
      false
    end
  end
end
