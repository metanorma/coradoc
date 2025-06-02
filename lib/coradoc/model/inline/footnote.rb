# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Footnote < Base
        attribute :text, :string
        attribute :id, :string

        asciidoc do
          map_model to: Coradoc::Element::Inline::Footnote
          map_attribute "id", to: :id
          map_attribute "text", to: :text
        end

        def to_asciidoc
          if id
            "footnote:#{id}[#{text}]"
          else
            "footnote:[#{text}]"
          end
        end
      end
    end
  end
end
