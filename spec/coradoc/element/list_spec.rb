require "spec_helper"

RSpec.describe Coradoc::Element::List do
  describe ".initialize" do
    it "initializes and exposes list" do
      items = ["Item 1", "Item 2", "Item 3"]

      list = Coradoc::Element::List::Unordered.new(items)

      expect(list.items).to eq(items)
    end
  end
end
