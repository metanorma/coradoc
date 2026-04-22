# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Block
        class Quote < Core
          attribute :delimiter_char, :string, default: -> { '_' }
          attribute :delimiter_len, :integer, default: -> { 4 }
        end
      end
    end
  end
end
