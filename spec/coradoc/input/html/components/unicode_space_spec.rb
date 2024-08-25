require "spec_helper"

describe Coradoc::Input::HTML do
  let(:input) do
    File.read("spec/coradoc/input/html/assets/unicode_space.html")
  end
  let(:document) { Nokogiri::HTML(input) }
  subject { Coradoc::Input::HTML.convert(input) }

  it { should include "\n| test1 | | test2 | \n" }
  it { should include "\ntest3\n" }
  it { should include "\n* test4\n" }
  it { should include "\n.. test5\n" }
  it { should include "\ntest6\n" }
  it { should include "\n==== test7\n" }
end
