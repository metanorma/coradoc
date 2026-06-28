require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::List::Nestable do
  # Since Nestable is just a subclass of Base providing a common type
  # we test instantiation and inheritance.
  describe '.new' do
    it 'can be instantiated' do
      nestable = described_class.new
      expect(nestable).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end
