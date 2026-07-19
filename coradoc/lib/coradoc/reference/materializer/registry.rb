# frozen_string_literal: true

module Coradoc
  module Reference
    module Materializer
      # Registry of materializers keyed by [kind, presentation, format].
      # Lookup falls back on +:any+ — so a materializer registered for
      # +[:link, :any, :html]+ handles every presentation in HTML.
      # Most specific key wins (concrete > :any).
      #
      # Format gems register their materializers process-wide via
      # +.register_global+ (OCP): every registry instance picks them up
      # on first use, and dispatch code never changes.
      class Registry
        # Core ships only the node-preserving fallback. Format-specific
        # materializers live in the format gems (coradoc-html,
        # coradoc-adoc, ...) and register globally at load time.
        BUILTINS = [Materializer::Passthrough].freeze

        @global_registrations = []

        GLOBAL_MUTEX = Mutex.new
        private_constant :GLOBAL_MUTEX

        class << self
          def register_global(klass)
            GLOBAL_MUTEX.synchronize do
              @global_registrations << klass unless @global_registrations.include?(klass)
            end
          end

          def global_registrations
            GLOBAL_MUTEX.synchronize { @global_registrations.dup }
          end

          def reset_globals!
            GLOBAL_MUTEX.synchronize { @global_registrations.clear }
          end
        end

        def initialize
          @by_key = {}
          @builtins_registered = false
        end

        def register(klass)
          ensure_builtins_registered!
          @by_key[EntryKey.new(klass.kind, klass.presentation, klass.format)] = klass
        end

        def lookup(kind:, presentation:, format:)
          ensure_builtins_registered!
          find_most_specific(kind, presentation, format) ||
            find_most_specific(kind, presentation, :any) ||
            find_most_specific(kind, :any, format) ||
            find_most_specific(kind, :any, :any) ||
            find_most_specific(:any, :any, :any)
        end

        def registered
          ensure_builtins_registered!
          @by_key.dup
        end

        def reset!
          @by_key.clear
          @builtins_registered = false
        end

        private

        def find_most_specific(kind, presentation, format)
          @by_key[EntryKey.new(kind.to_sym, presentation.to_sym, format.to_sym)]
        end

        def ensure_builtins_registered!
          return if @builtins_registered

          register_builtins!
          @builtins_registered = true
        end

        def register_builtins!
          (BUILTINS + self.class.global_registrations).each do |k|
            @by_key[EntryKey.new(k.kind, k.presentation, k.format)] = k
          end
        end

        # Internal composite key for the registry. Equality based on
        # the three symbol values so two equivalent tuples compare equal.
        class EntryKey
          attr_reader :kind, :presentation, :format

          def initialize(kind, presentation, format)
            @kind = kind.to_sym
            @presentation = presentation.to_sym
            @format = format.to_sym
          end

          def ==(other)
            other.is_a?(EntryKey) &&
              kind == other.kind &&
              presentation == other.presentation &&
              format == other.format
          end
          alias eql? ==

          def hash
            [kind, presentation, format].hash
          end
        end
        private_constant :EntryKey
      end
    end
  end
end
