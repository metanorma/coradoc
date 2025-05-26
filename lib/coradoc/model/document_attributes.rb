# frozen_string_literal: true

module Coradoc
  module Model
    class DocumentAttributes < Base
      attribute :data, Attribute, collection: true

      asciidoc do
        map_attribute "data", to: :data
      end

      def to_asciidoc
        if data.nil?
          return ""
        end

        data.map { |attribute|
          key = attribute.key.to_s
          value = attribute.value.to_s.delete("'")
          line_break = attribute.line_break

          v = value.to_s.empty? ? "" : " #{value}"
          ":#{key}:#{v}#{line_break}"
        }.join + "\n"
      end
    end
  end
end
