require "spec_helper"

describe Coradoc::Input::HTML::Converters do
  before { Coradoc::Input::HTML.config.unknown_tags = :raise }
  let(:converters) { Coradoc::Input::HTML::Converters }

  describe ".register and .unregister" do
    it "adds a converter mapping to the list" do
      expect do
        converters.lookup(:foo)
      end.to raise_error Coradoc::Input::HTML::UnknownTagError

      converters.register :foo, :foobar
      expect(converters.lookup(:foo)).to eq :foobar

      converters.unregister :foo
      expect do
        converters.lookup(:foo)
      end.to raise_error Coradoc::Input::HTML::UnknownTagError
    end
  end
end
