require "spec_helper"

describe Coradoc::Input::Html do
  subject { Coradoc::Input::Html.convert(input) }

  let(:input) do
    File.read("spec/coradoc/input/html/assets/unicode_space.html")
  end
  let(:document) { Nokogiri::HTML(input) }

  it { is_expected.to include "\n| test1 | | test2 | \n" }
  it { is_expected.to include "\ntest3\n" }
  it { is_expected.to include "\n* test4\n" }
  it { is_expected.to include "\n.. test5\n" }
  it { is_expected.to include "\ntest6\n" }
  it { is_expected.to include "\n==== test7\n" }
end
