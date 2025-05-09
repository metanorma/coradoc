require "spec_helper"

describe Coradoc::Input::Html do
  subject { described_class.convert(input) }

  let(:input) do
    File.read("spec/coradoc/input/html/assets/html_fragment.html")
  end
  let(:document) { Nokogiri::HTML(input) }

  it { is_expected.to eq("naked text 1\n\nparagraph text\n\nnaked text 2") }
end
