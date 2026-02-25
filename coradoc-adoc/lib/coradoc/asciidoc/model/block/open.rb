# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Block
        class Open < Core
          attribute :delimiter_char, :string, default: -> { '-' }
          attribute :delimiter_len, :integer, default: -> { 2 }
        end
      end
    end
  end
end
