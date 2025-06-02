# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Small < Base
        attribute :text, :string

        asciidoc do
          map_model to: Coradoc::Element::Inline::Small
          map_attribute "text", to: :text
        end

        def to_asciidoc
          "[.small]##{text}#"
        end
      end
    end
  end
end
