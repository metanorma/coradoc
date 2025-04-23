# frozen_string_literal: true

# require "lutaml/model"

module Coradoc
  module Model
    class Base < Lutaml::Model::Serializable
      attribute :id, :string
    end
  end
end
