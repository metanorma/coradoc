require "spec_helper"

describe Coradoc::Input::Html::Converters::Strong do
  let(:converter) { described_class.new }

  it "returns an empty string if the node is empty" do
    input = node_for("<strong></strong>")
    expect(converter.convert(input)).to eq ""
  end

  it "returns a space if the node contains just whitespace" do
    input = node_for("<strong> </strong>")
    expect(converter.convert(input)).to eq " "
  end

  it "returns just the content if the strong tag is nested in another strong" do
    input = node_for("<strong><strong>foo</strong></strong>")
    expect(
      converter.convert(
        input.children.first,
        already_strong: true,
      ),
    ).to eq "foo"
  end

  it "moves border whitespaces outside of the delimiters tag" do
    input = node_for("<strong> \n foo </strong>")
    expect(converter.convert(input)).to eq " *foo* "
  end
end
