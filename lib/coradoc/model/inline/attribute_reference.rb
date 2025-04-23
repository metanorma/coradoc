# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class AttributeReference < Base
        attribute :name, :string

        def to_asciidoc
          "{#{name}}"
        end
      end
    end
  end
end
