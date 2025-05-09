require "spec_helper"

describe Coradoc::Input::Html do
  subject { described_class.convert(input) }

  let(:input)    { File.read("spec/coradoc/input/html/assets/code.html") }
  let(:document) { Nokogiri::HTML(input) }

  it { is_expected.to match /inline `code` block/ }
  it { is_expected.to match /\nvar this;\nthis\.is/ }
  it { is_expected.to match /block"\)\nconsole/ }

  context "with github style code blocks" do
    subject { described_class.convert(input) }

    it { is_expected.to match /inline `code` block/ }
    it { is_expected.to match /\n\.\.\.\.\nvar this;\nthis/ }
    it { is_expected.to match /it is"\) ?\n	\n\.\.\.\./ }
  end

  context "code with indentation" do
    subject { described_class.convert(input) }

    it { is_expected.to match(/^tell application "Foo"\n/) }
    it { is_expected.to match(/^    beep\n/) }
    it { is_expected.to match(/^end tell\n/) }
  end
end
