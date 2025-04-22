# frozen_string_literal: true

module Coradoc
  module Model
    class DocumentAttributes < Base
      attribute :data, :hash

      asciidoc do
        map_attribute "data", to: :data
      end

      def to_hash
        data.to_h do |attribute|
          [attribute.key.to_s, attribute.value.to_s.delete("'")]
        end
      end

      def to_asciidoc
        "#{to_hash.map do |key, value|
          v = value.to_s.empty? ? '' : " #{value}"
          ":#{key}:#{v}\n"
        end.join}\n"
      end
    end
  end
end
