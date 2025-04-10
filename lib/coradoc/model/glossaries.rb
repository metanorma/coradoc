# frozen_string_literal: true

module Coradoc
  module Model
    class glossaries < Base
      attribute :items, :string, collection: true
    end
  end
end
