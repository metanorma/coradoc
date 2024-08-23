require "spec_helper"

describe Coradoc::ReverseAdoc do
  let(:input)    { File.read("spec/reverse_adoc/assets/unicode_space.html") }
  let(:document) { Nokogiri::HTML(input) }
  subject { Coradoc::ReverseAdoc.convert(input) }

  it { should include "\n| test1 | | test2 | \n" }
  it { should include "\ntest3\n" }
  it { should include "\n* test4\n" }
  it { should include "\n.. test5\n" }
  it { should include "\ntest6\n" }
  it { should include "\n==== test7\n" }
end
