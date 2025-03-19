require "spec_helper"

describe Coradoc::Input::Html::Config do
  describe "#with" do
    let(:config) { Coradoc::Input::Html.config }

    it "takes additional options into account" do
      config.with(tag_border: :foobar) do
        expect(Coradoc::Input::Html.config.tag_border).to eq :foobar
      end
    end

    it "returns the result of a given block" do
      expect(config.with { :something }).to eq :something
    end

    it "resets to original settings afterwards" do
      config.tag_border = :foo
      config.with(tag_border: :bar) do
        expect(Coradoc::Input::Html.config.tag_border).to eq :bar
      end
      expect(Coradoc::Input::Html.config.tag_border).to eq :foo
    end
  end
end
