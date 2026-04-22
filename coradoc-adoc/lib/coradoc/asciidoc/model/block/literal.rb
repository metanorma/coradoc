# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Block
        class Literal < Core
          attribute :delimiter_char, :string, default: -> { '.' }
          attribute :delimiter_len, :integer, default: -> { 4 }
        end
      end
    end
  end
end
