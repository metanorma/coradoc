require "spec_helper"

describe Coradoc::Input::Html do
  subject { described_class.convert(input, split_sections: level) }

  let(:input) { File.read("spec/coradoc/input/html/assets/sections.html") }
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
  let(:document) { Nokogiri::HTML(input) }
  let(:level)    { 1 }

  context "splitting in level nil" do
    let(:level) { nil }

    it { is_expected.not_to be_a Hash }
  end

  shared_examples "can split and generate correct index" do
    it { is_expected.to be_a Hash }

    it "has a correct keys" do
      expect(subject.keys).to be == expected_sections
    end

    it "has a correct index" do
      section_content = l1sections.compact.map do |i|
        "include::#{i}[]\n\n"
      end.join
      expect(subject[nil]).to be == "[[__brokendiv]]\nPreface\n#{section_content}"
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

    it "has a correct level2 index" do
      expect(subject["sections/section-02.adoc"]).to be ==
        "== Section 2\n\nThis document describes something.\n\ninclude::../sections/section-02/section-01.adoc[]\n\ninclude::../sections/section-02/section-02.adoc[]\n\ninclude::../sections/section-02/section-03.adoc[]\n\n"
    end
  end
end
