require "spec_helper"

describe Coradoc::Input::HTML do
  let(:input)    { File.read("spec/coradoc/input/html/assets/quotation.html") }
  let(:document) { Nokogiri::HTML(input) }
  subject { Coradoc::Input::HTML.convert(input) }

  it { is_expected.to match /\n      Block of code$/ }
  it {
    is_expected.to include "\n____\nFirst quoted paragraph\n\nSecond quoted paragraph\n____\n"
  }
end
