# frozen_string_literal: true

module Coradoc
  # Include resolver protocol.
  #
  # A resolver is anything that responds to +#call(target:, base_dir:,
  # options:, context:)+ and returns the raw bytes of the included
  # target, BEFORE tag/line/indent selectors are applied. Selectors
  # live in the processor; the resolver only fetches bytes.
  #
  # The default resolver is {IncludeResolver::Filesystem}. Custom
  # resolvers (HTTP, database, generated) plug in here without changes
  # to the processor (OCP).
  #
  # Contract:
  #   call(target:, base_dir:, options:, context:) -> String
  #     target   String              path/URL as authored
  #     base_dir String              absolute path to the including file's dir
  #     options  CoreModel::IncludeOptions
  #     context  Hash                recursion state (depth, parent_chain, ...)
  #
  #   Raises Coradoc::IncludeNotFoundError if the target cannot be located.
  #   The processor's missing-file policy decides what to do with that.
  #
  # This base class is provided for documentation and for is_a? checks.
  # Custom resolvers do NOT need to inherit — duck typing on the call
  # signature is sufficient. ( SPEC 13 uses a bare Object with
  # define_singleton_method, which we support.)
  class IncludeResolver
    autoload :Filesystem, "#{__dir__}/include_resolver/filesystem"

    def call(target:, base_dir:, options:, context:)
      raise NotImplementedError,
            "#{self.class} must implement #call(target:, base_dir:, options:, context:)"
    end

    class << self
      # Coerce +value+ into something that quacks like an IncludeResolver.
      # - Already-callable objects (respond to :call) are returned as-is.
      # - Symbols are interpreted as built-in names: +:filesystem+,
      #   +:filesystem_strict+ (path-traversal protection on).
      #
      # @param value [Object, nil] the resolver or built-in name
      # @param base_dir [String] required for built-in filesystem resolvers
      # @param allow_unsafe [Boolean] opt-out of path-traversal protection
      # @return [Object] something callable as a resolver
      def coerce(value, base_dir:, allow_unsafe: false)
        return Filesystem.new(base_dir: base_dir, allow_unsafe: allow_unsafe) if value.nil?

        case value
        when Symbol then coerce_symbol(value, base_dir: base_dir, allow_unsafe: allow_unsafe)
        else value
        end
      end

      private

      def coerce_symbol(name, base_dir:, allow_unsafe:)
        case name
        when :filesystem then Filesystem.new(base_dir: base_dir, allow_unsafe: allow_unsafe)
        else
          raise ArgumentError, "Unknown include resolver: #{name.inspect}"
        end
      end
    end
  end
end
