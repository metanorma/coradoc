# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        class Passthrough < Base
          attribute :content, :string
          attribute :form, :string, default: -> { 'triple' }
        end
      end
    end
  end
end
