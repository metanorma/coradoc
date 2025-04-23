# frozen_string_literal: true

module Coradoc
  module Model
    class AttributeList < Base
      attribute :positional, AttributeListAttribute, collection: true,
                                                     initialize_empty: true
      attribute :named, NamedAttribute, collection: true, initialize_empty: true
      attribute :rejected_positional, RejectedPositionalAttribute,
                collection: true, initialize_empty: true
      attribute :rejected_named, NamedAttribute, collection: true,
                                                 initialize_empty: true

      asciidoc do
        map_attribute "positional", to: :positional
        map_attribute "named", to: :named
        map_attribute "rejected_positional", to: :rejected_positional
        map_attribute "rejected_named", to: :rejected_named
      end

      def add_positional(*attr)
        @positional << AttributeListAttribute.new(value: attr)
      end

      def add_named(name, value)
        @named << NamedAttribute.new(name:, value:)
      end

      # TODO: test & verify
      # def to_asciidoc
      def to_asciidoc(show_empty: false)
        return "[]" if [positional, named].all?(&:empty?)

        adoc = ""
        adoc << positional.map(&:to_asciidoc).join(",")
        adoc << "," if positional.any? && named.any?
        adoc << named.map(&:to_asciidoc).join(",")

        if !empty? || (empty? && show_empty)
          "[#{adoc}]"
        elsif empty? && !show_empty
          adoc
        end
      end

      private

      def empty?
        positional.empty? && named.empty?
      end
    end
  end
end
