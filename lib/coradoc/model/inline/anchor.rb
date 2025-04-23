# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Anchor < Base
        attribute :id, :string

        asciidoc do
          map_attribute "id", to: :id
        end

        def validate
          errors = super
          if id.nil? || id.empty?
            errors <<
              Lutaml::Model::Error.new("ID cannot be nil or empty for Anchor")
          end
        end

        def to_asciidoc
          "[[#{id}]]"
        end
      end
    end
  end
end
