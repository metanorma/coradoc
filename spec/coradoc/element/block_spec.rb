require "spec_helper"

RSpec.describe Coradoc::Element::Block do
  describe ".initialize" do
    it "initializes and exposes attributes" do
      title = "This is a block title"
      block = Coradoc::Element::Block::Quote.new(title)

      expect(block.title).to eq(title)
      expect(block.lines).to be_empty
      expect(block.attributes).to eq({})
    end
  end

  describe "#type" do
    it "translates delimiter to proper types" do
      title = "Block title"
      delimiter = "____"

      block = Coradoc::Element::Block::Core.new(title, delimiter: delimiter)

      expect(block.title).to eq(title)
      expect(block.type).to eq(:quote)
    end
  end
end
