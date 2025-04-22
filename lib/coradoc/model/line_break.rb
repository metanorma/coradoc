# frozen_string_literal: true

module Coradoc
  module Model
    class LineBreak < Base
      attribute :line_break, :string, default: -> { "" }

      def to_asciidoc
        line_break
      end
    end
  end
end
