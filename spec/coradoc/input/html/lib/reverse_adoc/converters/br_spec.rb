require "spec_helper"

describe Coradoc::Input::HTML::Converters::Br do
  let(:converter) { Coradoc::Input::HTML::Converters::Br.new }

  it "just converts into two spaces and a newline" do
    expect(converter.convert(:anything)).to eq " \+\n"
  end
end
