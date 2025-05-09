require "spec_helper"

RSpec.describe Coradoc::Element::Header do
  describe ".initialize" do
    it "initializes and exposes attributes" do
      title = "This is test title"
      revision = Coradoc::Element::Revision.new(1.0, date: "2023-01-01")
      author = Coradoc::Element::Author.new("John", "Doe", "john@example.com")

      header = described_class.new(
        title, author: author, revision: revision
      )

      expect(header.title).to eq(title)
      expect(header.author).to eq(author)
      expect(header.revision).to eq(revision)
    end
  end
end
