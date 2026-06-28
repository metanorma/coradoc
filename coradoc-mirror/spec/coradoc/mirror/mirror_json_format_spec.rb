# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Coradoc::Mirror::MirrorJsonFormat do
  let(:document) do
    Coradoc::CoreModel::DocumentElement.new(
      title: 'Test',
      children: [
        Coradoc::CoreModel::ParagraphBlock.new(content: 'Hello')
      ]
    )
  end

  describe '.serialize' do
    it 'serializes a CoreModel document to Mirror JSON' do
      json = described_class.serialize(document)
      parsed = JSON.parse(json)

      expect(parsed['type']).to eq('doc')
      expect(parsed['attrs']['title']).to eq('Test')
      expect(parsed['content'].first['type']).to eq('paragraph')
    end
  end

  describe '.parse_to_core' do
    it 'raises UnsupportedFormatError' do
      expect do
        described_class.parse_to_core('{}')
      end.to raise_error(Coradoc::UnsupportedFormatError, /Parsing from mirror JSON is not supported/)
    end
  end

  describe '.serialize?' do
    it 'returns true' do
      expect(described_class.serialize?).to be true
    end
  end

  describe '.handles_model?' do
    it 'returns false' do
      expect(described_class.handles_model?(Object.new)).to be false
    end
  end
end
