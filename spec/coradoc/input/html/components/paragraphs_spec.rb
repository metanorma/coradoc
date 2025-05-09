require "spec_helper"

describe Coradoc::Input::Html do
  subject { Coradoc::Input::Html.convert(input) }

  let(:input)    { File.read("spec/coradoc/input/html/assets/paragraphs.html") }
  let(:document) { Nokogiri::HTML(input) }

  it { is_expected.not_to start_with "\n\n" }
  it { is_expected.to start_with "First content\n\nSecond content\n\n" }
  it { is_expected.to include "\n\n_Complex_\n\n\.\.\.\.\n\n        Content\n" }
  it { is_expected.to include "*Trailing whitespace:*" }
  it { is_expected.to include "*Trailing non-breaking space:&nbsp;*" }
  it { is_expected.to include "*_Combination:&nbsp;_*" }
end
