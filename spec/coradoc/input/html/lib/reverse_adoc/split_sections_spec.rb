require "spec_helper"

describe Coradoc::Input::HTML do
  let(:input)    { File.read("spec/coradoc/input/html/assets/sections.html") }
  let(:document) { Nokogiri::HTML(input) }
  let(:level)    { 1 }
  subject { Coradoc::Input::HTML.convert(input, split_sections: level) }
  let(:l1sections) do
    %w[sections/section-01.adoc
       sections/section-02.adoc
       sections/section-03.adoc] + [nil]
  end
  let(:l2sections) do
    %w[sections/section-01.adoc
       sections/section-02/section-01.adoc
       sections/section-02/section-02.adoc
       sections/section-02/section-03.adoc
       sections/section-02.adoc
       sections/section-03/section-01.adoc
       sections/section-03.adoc] + [nil]
  end

  context "splitting in level nil" do
    let(:level) { nil }

    it { should_not be_a Hash }
  end

  shared_examples "can split and generate correct index" do
    it { should be_a Hash }
    it "should have a correct keys" do
      subject.keys.should be == expected_sections
    end

    it "should have a correct index" do
      section_content = l1sections.compact.map do |i|
        "include::#{i}[]\n\n"
      end.join
      subject[nil].should be == "[[__brokendiv]]\nPreface\n#{section_content}"
    end
  end

  context "splitting in level 1" do
    let(:level) { 1 }
    let(:expected_sections) { l1sections }

    include_examples "can split and generate correct index"
  end

  context "splitting in level 2" do
    let(:level) { 2 }
    let(:expected_sections) { l2sections }

    include_examples "can split and generate correct index"

    it "should have a correct level2 index" do
      subject["sections/section-02.adoc"].should be ==
        "== Section 2\n" +
          "\n" +
          "This document describes something.\n" +
          "\n" +
          "include::../sections/section-02/section-01.adoc[]\n" +
          "\n" +
          "include::../sections/section-02/section-02.adoc[]\n" +
          "\n" +
          "include::../sections/section-02/section-03.adoc[]\n" +
          "\n"
    end
  end
end
