require "spec_helper"

describe Coradoc::Input::HTML::Converters::P do
  let(:converter) { Coradoc::Input::HTML::Converters::P.new }

  it "converts p with anchor" do
    node = node_for("<p id='A'>puts foo</p>")
    expect(converter.convert(node)).to include "\n[[A]]\nputs foo"
  end
end
