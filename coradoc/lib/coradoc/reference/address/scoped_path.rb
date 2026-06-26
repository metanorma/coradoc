# frozen_string_literal: true

module Coradoc
  module Reference
    class Address < Lutaml::Model::Serializable
      # Scoped path — a path within a collection's namespace. The scope
      # identifies the collection (e.g. "ELF"); the target is the path
      # inside it ("5005:1"); the fragment is locality within that doc.
      #
      #   "ELF:5005:1#sec-3"  => scope "ELF", target "5005:1", fragment "sec-3"
      module ScopedPath
        module_function

        SCOPED_PATTERN = /\A([A-Z][A-Z0-9_\-]*):([\d:]+)(?:#(.*))?\z/

        def scheme_name
          :scoped_path
        end

        def matches?(raw)
          return false if raw.nil? || raw.empty?

          SCOPED_PATTERN.match?(raw.to_s)
        end

        def parse(raw)
          match = SCOPED_PATTERN.match(raw.to_s)
          raise Address::ParseError, "Invalid scoped path: #{raw.inspect}" unless match

          Address.new(
            scheme: 'scoped_path',
            scope: match[1],
            target: match[2],
            fragment: match[3]
          )
        end

        def serialize(address)
          base = "#{address.scope}:#{address.target}"
          return base unless address.fragment && !address.fragment.empty?

          "#{base}##{address.fragment}"
        end
      end
    end
  end
end
