# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Author information for document headers.
      #
      # Author metadata captures document author names and contact information.
      #
      # @!attribute [r] first_name
      #   @return [String, nil] Author's first name
      #
      # @!attribute [r] middle_name
      #   @return [String, nil] Author's middle name or initial
      #
      # @!attribute [r] last_name
      #   @return [String, nil] Author's last name
      #
      # @!attribute [r] email
      #   @return [String, nil] Author's email address
      #
      # @example Create an author
      #   author = Coradoc::AsciiDoc::Model::Author.new
      #   author.first_name = "John"
      #   author.last_name = "Doe"
      #   author.email = "john@example.com"
      #
      class Author < Base
        attribute :first_name, :string
        attribute :last_name, :string
        attribute :email, :string
        attribute :middle_name, :string
      end
    end
  end
end
