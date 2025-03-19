require "spec_helper"

describe Coradoc::Input::Html::Converters do
  before { Coradoc::Input::Html.config.unknown_tags = :raise }
  let(:converters) { Coradoc::Input::Html::Converters }

  describe ".register and .unregister" do
    it "adds a converter mapping to the list" do
      expect do
        converters.lookup(:foo)
      end.to raise_error Coradoc::Input::Html::UnknownTagError

      converters.register :foo, :foobar
      expect(converters.lookup(:foo)).to eq :foobar

      converters.unregister :foo
      expect do
        converters.lookup(:foo)
      end.to raise_error Coradoc::Input::Html::UnknownTagError
    end
  end
end
