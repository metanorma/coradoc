# frozen_string_literal: true

module Coradoc
  module Markdown
    # A typed key-value pair used wherever Markdown models need arbitrary
    # attributes (IAL key="value" pairs, extension options, etc.).
    #
    # Replaces raw Hash attributes so that every attribute on a model is
    # a typed lutaml-model declaration.
    #
    # @example
    #   NamedValue.new(name: "data-role", value: "main")
    class NamedValue < Base
      attribute :name, :string
      attribute :value, :string
    end
  end
end
