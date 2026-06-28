require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Inline::CrossReferenceArg do
  describe '.new' do
    it 'initializes with key, delimiter, and value' do
      arg = described_class.new(key: 'text', delimiter: '=', value: 'Reference')
      expect(arg.key).to eq('text')
      expect(arg.delimiter).to eq('=')
      expect(arg.value).to eq('Reference')
    end

    it 'initializes with defaults' do
      arg = described_class.new
      expect(arg.key).to be_nil
      expect(arg.delimiter).to be_nil
      expect(arg.value).to be_nil
    end
  end
end
