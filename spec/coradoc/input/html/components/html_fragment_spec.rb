require "spec_helper"

describe Coradoc::Input::HTML do
  let(:input) do
    File.read("spec/coradoc/input/html/assets/html_fragment.html")
  end
  let(:document) { Nokogiri::HTML(input) }
  subject { Coradoc::Input::HTML.convert(input) }

  it { is_expected.to eq("naked text 1\n\nparagraph text\n\nnaked text 2") }
end
