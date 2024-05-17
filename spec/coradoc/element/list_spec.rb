require "spec_helper"

RSpec.describe Coradoc::Element::List do
  describe ".initialize" do
    it "initializes and exposes list" do
      items = ["Item 1", "Item 2", "Item 3"]

      list = Coradoc::Element::List::Unordered.new(items)

      expect(list.items).to eq(items)
    end
    it "handles list continuations" do
      items2 = Coradoc::Element::ListItem.new(["Item 2a", "Item 2b", "Item 2c"])
      item1 = Coradoc::Element::ListItem.new("Item 1")
      items = [item1, items2]

      list = Coradoc::Element::List::Unordered.new(items)

      expect(list.to_adoc).to eq("\n\n* Item 1\n* Item 2a\n+\nItem 2b\n+\nItem 2c\n")
    end
    it "handles definition list" do
      # items = Coradoc::Element::ListItem.new(["Item1", "Item 2b", "Item 2c"])
      item = Coradoc::Element::ListItemDefinition.new("Coffee","Black hot drink")
      items = [item]

      list = Coradoc::Element::List::Definition.new(items)

      expect(list.to_adoc).to eq("\nCoffee:: Black hot drink\n")
    end
  end
end
