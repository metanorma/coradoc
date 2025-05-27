require "spec_helper"

describe Coradoc::Input::Html do
  let(:input) do
    File.read("spec/coradoc/input/html/assets/unknown_tags.html")
  end
  let(:document) { Nokogiri::HTML(input) }
  let(:result)   { described_class.convert(input) }

  context "with unknown_tags = :pass_through" do
    before do
      described_class.config.unknown_tags = :pass_through
    end

    it { expect(result).to include "<bar>Foo with bar</bar>" }
  end

  context "with unknown_tags = :raise" do
    before do
      described_class.config.unknown_tags = :raise
    end

    it {
      expect {
        result
      }.to raise_error(Coradoc::Input::Html::UnknownTagError)
    }
  end

  context "with unknown_tags = :drop" do
    before do
      described_class.config.unknown_tags = :drop
    end

    it { expect(result).to eq "" }
  end

  context "with unknown_tags = :bypass" do
    before do
      described_class.config.unknown_tags = :bypass
    end

    it { expect(result).to eq "Foo with bar\n\n" }
  end

  context "with unknown_tags = :something_wrong" do
    before do
      described_class.config.unknown_tags = :something_wrong
    end

    it {
      expect {
        result
      }.to raise_error(Coradoc::Input::Html::InvalidConfigurationError)
    }
  end
end
