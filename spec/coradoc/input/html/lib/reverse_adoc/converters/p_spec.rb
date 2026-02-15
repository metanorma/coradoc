require "spec_helper"

describe Coradoc::Input::Html::Converters::P do
  let(:converter) { described_class.new }

  it "converts p with anchor" do
    node = node_for("<p id='A'>puts foo</p>")
    expect(converter.convert(node)).to include "\n[[A]]\nputs foo"
  end
end
