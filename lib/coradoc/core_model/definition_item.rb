# frozen_string_literal: true

module Coradoc
  module CoreModel
    class DefinitionItem < Base
      attribute :term, :string
      attribute :definitions, :string, collection: true

      def initialize(args = {})
        @term_children = args.delete(:term_children) || []
        @definition_children = args.delete(:definition_children) || []
        super(args)
      end

      attr_reader :term_children, :definition_children

      def term_children=(value)
        @term_children = value || []
      end

      def definition_children=(value)
        @definition_children = value || []
      end

      def term_renderable
        return term if term_children.nil? || term_children.none?
        return term if term && term_children.all?(String)

        term_children
      end

      def definition_renderable
        return definitions if definition_children.nil? || definition_children.none?
        return definitions if definition_children.all?(String)

        definition_children
      end

      private

      def comparable_attributes
        super + %i[term definitions term_children definition_children]
      end
    end
  end
end
