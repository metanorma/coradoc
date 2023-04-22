module Coradoc
  class Document::Author
    attr_reader :email, :last_name, :first_name

    def initialize(first_name, last_name, email)
      @email = email
      @last_name = last_name
      @first_name = first_name
    end
  end
end
