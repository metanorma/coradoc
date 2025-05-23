require "spec_helper"

RSpec.describe Coradoc::Element::Header do
  describe ".initialize" do
    it "initializes and exposes attributes" do
      title = "This is test title"
      revision = Coradoc::Element::Revision.new(number: "1.0",
                                                date: "2023-01-01")
      author = Coradoc::Element::Author.new(first_name: "John",
                                            last_name: "Doe", email: "john@example.com")

      header = described_class.new(title:, author:, revision:)

      expect(header.title).to eq(title)
      expect(header.author).to eq(author)
      expect(header.revision).to eq(revision)
    end
  end
end
