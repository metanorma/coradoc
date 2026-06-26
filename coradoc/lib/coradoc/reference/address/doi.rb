# frozen_string_literal: true

module Coradoc
  module Reference
    class Address < Lutaml::Model::Serializable
      # DOI — Digital Object Identifier. Regex per the DOI handbook.
      module Doi
        module_function

        DOI_PATTERN = %r{\A(10\.\d{4,}/[^\s#]+)(?:#(.*))?\z}

        def scheme_name
          :doi
        end

        def matches?(raw)
          return false if raw.nil? || raw.empty?

          DOI_PATTERN.match?(raw.to_s)
        end

        def parse(raw)
          match = DOI_PATTERN.match(raw.to_s)
          raise Address::ParseError, "Invalid DOI: #{raw.inspect}" unless match

          target = match[1]
          fragment = match[2]
          Address.new(scheme: 'doi', target: target, fragment: fragment)
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
