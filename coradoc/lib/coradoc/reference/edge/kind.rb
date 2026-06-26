# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Registry mapping kind symbol → Entry(name, options_class).
      # Built-in kinds are registered lazily on first access. External
      # gems add kinds via +Edge.register_kind+ (OCP).
      module Kind
        @entries = {}
        @builtins_registered = false

        Entry = Struct.new(:name, :options_class)
        private_constant :Entry

        class << self
          def register(name, options_class: nil)
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
            return if @builtins_registered

            register(:navigation, options_class: Edge::NavigationOptions)
            register(:citation, options_class: Edge::CitationOptions)
            register(:link, options_class: Edge::LinkOptions)
            register(:include, options_class: Edge::IncludeOptions)
            register(:image_ref, options_class: Edge::ImageRefOptions)
            register(:footnote_ref, options_class: Edge::FootnoteRefOptions)
            @builtins_registered = true
          end
        end
      end
    end
  end
end
