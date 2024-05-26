require "spec_helper"

describe Coradoc::ReverseAdoc do
  let(:input)    { File.read("spec/reverse_adoc/assets/anchors.html") }
  let(:document) { Nokogiri::HTML(input) }
  subject { Coradoc::ReverseAdoc.convert(input) }

  it { is_expected.to include "http://foobar.com[Foobar]" }
  it { is_expected.to include "http://foobar.com[Fubar]" }
  it { is_expected.to include 'http://foobar.com[f\*\*\*\*\* up beyond all redemption]' }
  it { is_expected.to include "http://strong.foobar.com[*Strong foobar*]" }

  it {
    is_expected.to include "There should be space before but not after the anchor AA http://foobar.com[stripped]AA."
  }

  it {
    is_expected.to include "There shouldn't be a space before an anchor if constrained http://foobar.com[stripped]."
  }

  it {
    is_expected.to include " do not ignore link:foo.html[] anchor tags with no link text "
  }
  it {
    is_expected.to include " link <<content,internal jumplinks>> with anchors "
  }
  it {
    is_expected.to include " link <<content2>>internal jumplinks without anchors "
  }
  it { is_expected.to include " treat [[content]] as bookmarks " }

  it { is_expected.to include "<<a_bspaced,Double \\_\\_ anchor with space>>" }
  it { is_expected.to include "[[a_bspaced]]" }
  it { is_expected.to include "[[a_Foreword]]\n== Text" }
  it { is_expected.not_to include "[[_Toc12345]]" }

  it { is_expected.to include "convert a link directly to text: https://example.com/directly_to_text if both" }
end
