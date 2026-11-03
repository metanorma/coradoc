# frozen_string_literal: true

module Coradoc
  module Markdown
    # Represents an Inline Attribute List (IAL) or Attribute List Definition (ALD)
    #
    # IAL syntax: {:.class #id key="value"}
    # ALD syntax: {:name: #id .class key="value"}
    #
    # Examples:
    #   {:.highlight} - adds class "highlight"
    #   {#introduction} - sets id to "introduction"
    #   {:key="value"} - sets attribute key="value"
    #   {:name: #id .class} - defines ALD named "name"
    #
    class AttributeList < Base
      attribute :id, :string
      attribute :classes, :string, collection: true, default: []
      attribute :attributes, NamedValue, collection: true, default: []
      attribute :name, :string # For ALD - the reference name

      prepend Behaviors::AttributeList
    end
  end
end
