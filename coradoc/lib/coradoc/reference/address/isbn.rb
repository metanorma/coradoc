# frozen_string_literal: true

module Coradoc
  module Reference
    class Address < Lutaml::Model::Serializable
      # ISBN — book identifier. Recognizes the "ISBN" prefix (case
      # insensitive, optional) and either ISBN-10 or ISBN-13 digits.
      module Isbn
        module_function

        ISBN_PATTERN = /\AISBN\s+([\d\-Xx]+)\z/i

        def scheme_name
          :isbn
        end

        def matches?(raw)
          return false if raw.nil? || raw.empty?

          ISBN_PATTERN.match?(raw.to_s)
        end

        def parse(raw)
          match = ISBN_PATTERN.match(raw.to_s)
          raise Address::ParseError, "Invalid ISBN: #{raw.inspect}" unless match

          target = match[1]
          Address.new(scheme: 'isbn', target: target)
        end

        def serialize(address)
          "ISBN #{address.target}"
        end
      end
    end
  end
end
