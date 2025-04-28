require "spec_helper"

RSpec.describe Coradoc::Model::AttributeList do
  describe ".initialize" do
    it "initializes with empty collections" do
      list = described_class.new

      expect(list.positional).to eq([])
      expect(list.named).to eq([])
      expect(list.rejected_positional).to eq([])
      expect(list.rejected_named).to eq([])
    end
  end

  describe "#add_positional" do
    let(:list) { described_class.new }

    it "adds single positional attribute" do
      list.add_positional("value1")

      expect(list.positional.length).to eq(1)
      expect(list.positional.first).to be_a(Coradoc::Model::AttributeListAttribute)
      expect(list.positional.first.value).to eq(["value1"])
    end

    it "adds multiple positional attributes" do
      list.add_positional("value1", "value2", "value3")

      expect(list.positional.length).to eq(1)
      expect(list.positional.first.value).to eq(["value1", "value2", "value3"])
    end
  end

  describe "#add_named" do
    let(:list) { described_class.new }

    it "adds named attribute" do
      list.add_named(:format, "pdf")

      expect(list.named.length).to eq(1)
      expect(list.named.first).to be_a(Coradoc::Model::NamedAttribute)
      expect(list.named.first.name).to eq(:format)
      expect(list.named.first.value).to eq("pdf")
    end

    it "allows multiple named attributes" do
      list.add_named(:format, "pdf")
      list.add_named(:lang, "en")

      expect(list.named.length).to eq(2)
      expect(list.named.map(&:name)).to eq([:format, :lang])
      expect(list.named.map(&:value)).to eq(["pdf", "en"])
    end
  end

  describe "#to_asciidoc" do
    let(:list) { described_class.new }

    before do
      allow_any_instance_of(Coradoc::Model::AttributeListAttribute)
        .to receive(:to_asciidoc) { |instance| instance.value.join(",") }

      allow_any_instance_of(Coradoc::Model::NamedAttribute)
        .to receive(:to_asciidoc) { |instance| "#{instance.name}=#{instance.value}" }
    end

    it "returns empty brackets when empty and show_empty is true" do
      expect(list.to_asciidoc(show_empty: true)).to eq("[]")
    end

    it "returns empty string when empty and show_empty is false" do
      expect(list.to_asciidoc(show_empty: false)).to eq("")
    end

    it "formats positional attributes" do
      list.add_positional("val1", "val2")
      expect(list.to_asciidoc).to eq("[val1,val2]")
    end

    it "formats named attributes" do
      list.add_named(:key1, "val1")
      list.add_named(:key2, "val2")
      expect(list.to_asciidoc).to eq("[key1=val1,key2=val2]")
    end

    it "combines positional and named attributes" do
      list.add_positional("pos1", "pos2")
      list.add_named(:key1, "val1")

      expect(list.to_asciidoc).to eq("[pos1,pos2,key1=val1]")
    end

    it "handles single positional attribute" do
      list.add_positional("single")
      expect(list.to_asciidoc).to eq("[single]")
    end

    it "handles single named attribute" do
      list.add_named(:key, "value")
      expect(list.to_asciidoc).to eq("[key=value]")
    end
  end

  describe "#empty?" do
    let(:list) { described_class.new }

    it "returns true when both positional and named are empty" do
      expect(list.send(:empty?)).to be true
    end

    it "returns false when has positional attributes" do
      list.add_positional("value")
      expect(list.send(:empty?)).to be false
    end

    it "returns false when has named attributes" do
      list.add_named(:key, "value")
      expect(list.send(:empty?)).to be false
    end

    it "ignores rejected attributes" do
      list.rejected_positional << "rejected"
      list.rejected_named << "rejected"
      expect(list.send(:empty?)).to be true
    end
  end
end
