require "spec_helper"

describe Coradoc::Input::Html::Converters::Br do
  let(:converter) { described_class.new }

  it "just converts into two spaces and a newline" do
    expect(converter.convert(:anything)).to eq " +\n"
  end
end
