require "spec_helper"

describe Coradoc::ReverseAdoc::Converters::Mark do
  let(:converter) { Coradoc::ReverseAdoc::Converters::Mark.new }

  it "renders mark" do
    input = node_for("<mark>A</mark>")
    expect(converter.convert(input)).to eq "#A#"
  end
end
