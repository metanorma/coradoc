require "spec_helper"

describe Coradoc::ReverseAdoc do
  let(:input)    { File.read("spec/reverse_adoc/assets/html_fragment.html") }
  let(:document) { Nokogiri::HTML(input) }
  subject { Coradoc::ReverseAdoc.convert(input) }

  it { is_expected.to eq("naked text 1\n\nparagraph text\n\nnaked text 2") }
end
