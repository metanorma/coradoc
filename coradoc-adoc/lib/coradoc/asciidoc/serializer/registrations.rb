# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      # Trigger loading of all serializer registrations.
      #
      # Each serializer file self-registers when loaded via
      # `ElementRegistry.register(...)` at file bottom. Walking the
      # serializers directory is the single source of truth for "which
      # serializers exist" — adding a file is the only step required for
      # it to register.
      module Registrations
        class << self
          def load_all!
            Dir["#{__dir__}/serializers/**/*.rb"].sort.each { |path| require path }
            true
          end
        end

        load_all!
      end
    end
  end
end
