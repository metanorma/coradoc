# frozen_string_literal: true

module Coradoc
  module Markdown
    class Serializer
      # Type-keyed dispatch table for element serializers.
      #
      # Each entry is a tuple of (serializer_instance, priority). Dispatch
      # resolves the highest-priority entry whose declared `handles?` predicate
      # accepts the element. This lets specialized serializers (e.g. one that
      # targets a specific CoreModel subclass) override generic ones without
      # modifying the registry lookup logic — Open/Closed.
      class Registry
        class Entry < Struct.new(:serializer, :priority)
          include Comparable

          def <=>(other)
            priority <=> other.priority
          end
        end

        def initialize
          @entries = Hash.new { |h, k| h[k] = [] }
        end

        def register(serializer, priority: 0)
          klass = serializer.handles_type
          raise ArgumentError, "Serializer #{serializer.class} declares no handles_type" unless klass

          @entries[klass] << Entry.new(serializer, priority)
          @entries[klass].sort!
          serializer
        end

        def lookup(element)
          each_candidate(element).first&.serializer
        end

        def lookup!(element)
          lookup(element) || raise(ArgumentError,
                                   "Unknown element type for serialization: #{element.class}. " \
                                     'Expected a known Markdown model type.')
        end

        private

        def each_candidate(element)
          return enum_for(:each_candidate, element) unless block_given?

          walked = element.class.ancestors
          walked.each do |klass|
            @entries[klass].sort_by { |e| -e.priority }.each do |entry|
              next unless entry.serializer.handles?(element)

              yield entry
            end
          end
        end
      end
    end
  end
end
