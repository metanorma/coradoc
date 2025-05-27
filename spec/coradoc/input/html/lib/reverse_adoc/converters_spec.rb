require "spec_helper"

describe Coradoc::Input::Html::Converters do
  before do
    Coradoc::Input::Html.config.unknown_tags = :raise
  end

  let(:converters) { described_class }

  describe ".register and .unregister" do
    it "adds a converter mapping to the list" do
      expect {
        converters.lookup(:foo)
      }.to raise_error Coradoc::Input::Html::UnknownTagError

      converters.register :foo, :foobar
      expect(converters.lookup(:foo)).to eq :foobar

      converters.unregister :foo
      expect {
        converters.lookup(:foo)
      }.to raise_error Coradoc::Input::Html::UnknownTagError
    end
  end
end
