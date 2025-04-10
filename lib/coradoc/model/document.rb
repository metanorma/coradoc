# frozen_string_literal: true

require_relative "base"
require_relative "title"
require_relative "document_attributes"
require_relative "header"
require_relative "section"

module Coradoc
  module Model
    class Document < Base
      attribute :title, Title
      attribute :document_attributes, DocumentAttributes, default: -> {
        DocumentAttributes.new
      }
      attribute :header, Header
      attribute :sections, Section, collection: true, initialize_empty: true
      attribute :authors, Author, collection: true, initialize_empty: true
      attribute :revisions, Revision, collection: true, initialize_empty: true

      asciidoc do
        map_content to: :content
        map_attribute :title, to: :title
        map_attribute :document_attributes, to: :attributes
        map_attribute :header, to: :header
        map_attribute :sections, to: :sections
        map_attribute :authors, to: :authors
        map_attribute :revisions, to: :revisions
      end
    end
  end
end
