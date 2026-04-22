# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      class Glossaries < Base
        attribute :items, :string, collection: true
      end
    end
  end
end
