# frozen_string_literal: true

module Coradoc
  module Reference
    class Address < Lutaml::Model::Serializable
      # ISBN — book identifier. Recognizes an optional "ISBN" prefix
      # (case insensitive) and either ISBN-10 or ISBN-13 digits. Bare
      # numbers must be long enough to be ISBN-shaped so short numeric
      # anchors are not claimed.
      module Isbn
        module_function

        ISBN_PATTERN = /\A(?:ISBN\s+)?(\d[\d\-Xx]{8,16})\z/i

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
