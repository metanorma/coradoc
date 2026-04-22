# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      class NamedAttribute < Base
        attribute :name, :string
        attribute :value, :string, collection: true, initialize_empty: true
      end
    end
  end
end
