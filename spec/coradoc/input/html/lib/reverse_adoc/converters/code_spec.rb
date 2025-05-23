require "spec_helper"

describe Coradoc::Input::Html::Converters::Code do
  let(:converter) { described_class.new }

  it "converts as backtick" do
    node = node_for("<code>puts foo</code>")
    expect(converter.convert(node)).to include "`puts foo`"
  end

  it "converts as backtick" do
    node = node_for("<tt>puts foo</tt>")
    expect(converter.convert(node)).to include "`puts foo`"
  end
end
