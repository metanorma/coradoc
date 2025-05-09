require "spec_helper"

describe Coradoc::Input::Html::Converters::Li do
  let(:converter) { described_class.new }

  it "does not fail without a valid parent context" do
    input = node_for("<li>foo</li>")
    result = converter.convert(input)
    expect(result).to eq " foo\n"
  end
end
