require "spec_helper"

describe Coradoc::Input::HTML::Converters::Q do
  let(:converter) { Coradoc::Input::HTML::Converters::Q.new }

  it "renders q" do
    input = node_for("<q>A</q>")
    expect(converter.convert(input)).to eq '"A"'
  end
end
