require "spec_helper"

describe Coradoc::Input::HTML::Converters::Aside do
  let(:converter) { Coradoc::Input::HTML::Converters::Aside.new }

  it "converts aside" do
    input = node_for("<aside><ul><li>foo</li></ul></aside>")
    result = converter.convert(input)
    expect(result).to eq "\n\n\*\*\*\*\n\n\n* foo\n\n\*\*\*\*\n\n"
  end
end
