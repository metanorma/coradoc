# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      class Highlight < TextElement
        attribute :unconstrained, :boolean, default: -> { false }
      end
    end
  end
end
