require "spec_helper"

describe Coradoc::Input::HTML do
  let(:input) do
    File.read("spec/coradoc/input/html/assets/unknown_tags.html")
  end
  let(:document) { Nokogiri::HTML(input) }
  let(:result)   { Coradoc::Input::HTML.convert(input) }

  context "with unknown_tags = :pass_through" do
    before { Coradoc::Input::HTML.config.unknown_tags = :pass_through }

    it { expect(result).to include "<bar>Foo with bar</bar>" }
  end

  context "with unknown_tags = :raise" do
    before { Coradoc::Input::HTML.config.unknown_tags = :raise }

    it {
      expect do
        result
      end.to raise_error(Coradoc::Input::HTML::UnknownTagError)
    }
  end

  context "with unknown_tags = :drop" do
    before { Coradoc::Input::HTML.config.unknown_tags = :drop }

    it { expect(result).to eq "" }
  end

  context "with unknown_tags = :bypass" do
    before { Coradoc::Input::HTML.config.unknown_tags = :bypass }

    it { expect(result).to eq "Foo with bar\n\n" }
  end

  context "with unknown_tags = :something_wrong" do
    before { Coradoc::Input::HTML.config.unknown_tags = :something_wrong }

    it {
      expect do
        result
      end.to raise_error(Coradoc::Input::HTML::InvalidConfigurationError)
    }
  end
end
