require "spec_helper"

describe Coradoc::ReverseAdoc::Converters do
  before { Coradoc::ReverseAdoc.config.unknown_tags = :raise }
  let(:converters) { Coradoc::ReverseAdoc::Converters }

  describe ".register and .unregister" do
    it "adds a converter mapping to the list" do
      expect do
        converters.lookup(:foo)
      end.to raise_error Coradoc::ReverseAdoc::UnknownTagError

      converters.register :foo, :foobar
      expect(converters.lookup(:foo)).to eq :foobar

      converters.unregister :foo
      expect do
        converters.lookup(:foo)
      end.to raise_error Coradoc::ReverseAdoc::UnknownTagError
    end
  end
end
