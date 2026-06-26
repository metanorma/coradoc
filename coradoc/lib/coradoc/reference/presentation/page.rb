# frozen_string_literal: true

require 'lutaml/model'

module Coradoc
  module Reference
    module Presentation
      # A page is the unit of output a Presentation produces. One HTML
      # file, one PDF page, one EPUB chapter — same data, different
      # materialization. The Materializer consumes Pages.
      class Page < Lutaml::Model::Serializable
        attribute :id, :string
        attribute :title, :string
        attribute :content, Coradoc::CoreModel::Base
        attribute :parent_id, :string
        attribute :order, :integer

        def ==(other)
          return false unless other.is_a?(Page)

          %i[id title content parent_id order].all? do |attr|
            public_send(attr) == other.public_send(attr)
          end
        end
        alias eql? ==

        def hash
          [id, title, content, parent_id, order].hash
        end
      end
    end
  end
end
