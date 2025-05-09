require "spec_helper"

describe Coradoc::Input::Html do
  let(:input) do
    File.read("spec/coradoc/input/html/assets/unknown_tags.html")
  end
  let(:document) { Nokogiri::HTML(input) }
  let(:result)   { described_class.convert(input) }

  context "with unknown_tags = :pass_through" do
    before { described_class.config.unknown_tags = :pass_through }

    it { expect(result).to include "<bar>Foo with bar</bar>" }
  end

  context "with unknown_tags = :raise" do
    before { described_class.config.unknown_tags = :raise }

    it {
      expect do
        result
      end.to raise_error(Coradoc::Input::Html::UnknownTagError)
    }
  end

  context "with unknown_tags = :drop" do
    before { described_class.config.unknown_tags = :drop }

    it { expect(result).to eq "" }
  end

  context "with unknown_tags = :bypass" do
    before { described_class.config.unknown_tags = :bypass }

    it { expect(result).to eq "Foo with bar\n\n" }
  end

  context "with unknown_tags = :something_wrong" do
    before { described_class.config.unknown_tags = :something_wrong }

    it {
      expect do
        result
      end.to raise_error(Coradoc::Input::Html::InvalidConfigurationError)
    }
  end
end
