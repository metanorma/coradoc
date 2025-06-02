# frozen_string_literal: true

module Coradoc
  module Model
    class LineBreak < Base
      attribute :line_break, :string, default: -> { "" }

      asciidoc do
        map_model to: Coradoc::Element::LineBreak
        map_attribute "line_break", to: :line_break
      end

      def to_asciidoc
        line_break
      end
    end
  end
end
