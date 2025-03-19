require "spec_helper"

describe Coradoc::Input::Html::Converters::Mark do
  let(:converter) { Coradoc::Input::Html::Converters::Mark.new }

  it "renders mark" do
    input = node_for("<mark>A</mark>")
    expect(converter.convert(input)).to eq "#A#"
  end
end
