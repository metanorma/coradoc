# frozen_string_literal: true

module Coradoc
  module Model
    class NamedAttribute < Base
      attribute :name, :string
      attribute :value, :string, collection: true, initialize_empty: true

      asciidoc do
        map_attribute "name", to: :name
        map_attribute "value", to: :value
      end

      def to_asciidoc
        if value.length == 1
          # Escape double quotes and backslashes
          v = value[0].gsub(/["\\]/) { |m| "\\#{m}" }
          if v.include?(",") || v.include?('"')
            v = "\"#{v}\""
          end
        else
          v = "\"#{value.join(',')}\""
        end
        [name.to_s, "=", v].join
      end
    end
  end
end
