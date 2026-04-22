# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Table element for AsciiDoc tables.
      #
      # Represents a table with rows and cells. Tables can have titles,
      # captions, and various formatting options.
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the table
      # @!attribute [r] title
      #   @return [String, nil] Optional table title
      # @!attribute [r] rows
      #   @return [Array<TableRow>] Table rows
      # @!attribute [r] content
      #   @return [String, nil] Optional string content
      # @!attribute [r] attrs
      #   @return [AttributeList] Additional table attributes
      #
      # @example Create a simple table
      #   table = Coradoc::AsciiDoc::Model::Table.new
      #   table.rows << Coradoc::AsciiDoc::Model::TableRow.new
      #
      class Table < Base
        include Coradoc::AsciiDoc::Model::Anchorable

        attribute :id, :string
        attribute :title, :string
        attribute :rows, Coradoc::AsciiDoc::Model::TableRow, collection: true
        attribute :content, :string
        # attribute :anchor, Inline::Anchor, default: -> {
        #   id.nil? ? nil : Inline::Anchor.new(id)
        # }
        attribute :attrs, Coradoc::AsciiDoc::Model::AttributeList
      end
    end
  end
end
