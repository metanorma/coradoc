# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Underline < Base
        attribute :text, :string

        asciidoc do
          map_attribute "text", to: :text
        end

        def to_asciidoc
          "[.underline]##{text}#"
        end
      end
    end
  end
end
