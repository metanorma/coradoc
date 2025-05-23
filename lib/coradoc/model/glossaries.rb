# frozen_string_literal: true

module Coradoc
  module Model
    class Glossaries < Base
      attribute :items, :string, collection: true
    end
  end
end
