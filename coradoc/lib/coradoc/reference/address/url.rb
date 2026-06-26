# frozen_string_literal: true

module Coradoc
  module Reference
    class Address < Lutaml::Model::Serializable
      # Absolute URL — anything with a recognized URL scheme prefix.
      # Fragment is the optional "#..." suffix.
      module Url
        module_function

        URL_PATTERN = %r{\A([a-z][a-z0-9+\-.]*)://([^#]+)(?:#(.*))?\z}i

        def scheme_name
          :url
        end

        def matches?(raw)
          return false if raw.nil? || raw.empty?

          URL_PATTERN.match?(raw.to_s)
        end

        def parse(raw)
          match = URL_PATTERN.match(raw.to_s)
          raise Address::ParseError, "Invalid URL: #{raw.inspect}" unless match

          target = "#{match[1]}://#{match[2]}"
          fragment = match[3]
          Address.new(scheme: 'url', target: target, fragment: fragment)
        end

        def serialize(address)
          base = address.target.to_s
          return base unless address.fragment && !address.fragment.empty?

          "#{base}##{address.fragment}"
        end
      end
    end
  end
end
