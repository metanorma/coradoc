# frozen_string_literal: true

module Coradoc
  module Model
    class Author < Base
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :email, :string
      attribute :middle_name, :string

      asciidoc do
        map_attribute "first_name", to: :first_name
        map_attribute "last_name", to: :last_name
        map_attribute "email", to: :email
        map_attribute "middle_name", to: :middle_name
      end

      def to_asciidoc
        adoc = [first_name, middle_name, last_name].compact.join(" ")
        adoc << " <#{email}>\n" if email
        adoc
      end
    end
  end
end
