# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      class LineBreak < Base
        attribute :line_break, :string, default: -> { '' }
      end
    end
  end
end
