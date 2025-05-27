# frozen_string_literal: true

module Coradoc
  module Model
    class RejectedPositionalAttribute < Base
      attribute :position, :integer
      attribute :value, :string

      asciidoc do
        map_attribute "position", to: :position
        map_attribute "value", to: :value
      end
    end
  end
end
