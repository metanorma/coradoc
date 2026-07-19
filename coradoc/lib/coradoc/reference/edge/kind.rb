# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Registry mapping kind symbol → Entry(name, options_class).
      # Built-in kinds are registered lazily on first access. External
      # gems add kinds via +Edge.register_kind+ (OCP).
      #
      # +register+ always forces builtin registration first, so an
      # external registration made before first use is never clobbered
      # by the lazy builtin pass.
      module Kind
        @entries = {}
        @builtins_registered = false
        @registering_builtins = false

        MUTEX = Mutex.new
        private_constant :MUTEX

        Entry = Struct.new(:name, :options_class)
        private_constant :Entry

        class << self
          def register(name, options_class: nil)
            ensure_builtins_registered! unless @registering_builtins
            @entries[name.to_sym] = Entry.new(name.to_sym, options_class)
          end

          def names
            ensure_builtins_registered!
            @entries.keys
          end

          def options_class_for(name)
            ensure_builtins_registered!
            @entries[name.to_sym]&.options_class
          end

          def entry_for(name)
            ensure_builtins_registered!
            @entries[name.to_sym]
          end

          def reset!
            @entries.clear
            @builtins_registered = false
          end

          def ensure_builtins_registered!
            MUTEX.synchronize do
              return if @builtins_registered

              @registering_builtins = true
              begin
                register(:navigation, options_class: Edge::NavigationOptions)
                register(:citation, options_class: Edge::CitationOptions)
                register(:link, options_class: Edge::LinkOptions)
                register(:include, options_class: Edge::IncludeOptions)
                register(:image_ref, options_class: Edge::ImageRefOptions)
                register(:footnote_ref, options_class: Edge::FootnoteRefOptions)
                @builtins_registered = true
              ensure
                @registering_builtins = false
              end
            end
          end
        end
      end
    end
  end
end
