require "spec_helper"

RSpec.describe Coradoc::Element::Author do
  describe ".initialize" do
    it "initializes and expsoses atributes" do
      first_name = "John"
      last_name = "Doe"
      email = "john.doe@example.com"

      author = described_class.new(first_name:, last_name:, email:)

      expect(author.email).to eq(email)
      expect(author.last_name).to eq(last_name)
      expect(author.first_name).to eq(first_name)
    end
  end
end
