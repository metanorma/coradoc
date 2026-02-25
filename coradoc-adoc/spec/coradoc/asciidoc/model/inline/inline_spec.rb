# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Bold do
  describe '#initialize' do
    it 'creates bold with content' do
      bold = described_class.new(content: 'important text')

      expect(bold.content).to eq('important text')
    end

    it 'creates bold with array content' do
      bold = described_class.new(content: ['text'])

      expect(bold.content).to eq(['text'])
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Italic do
  describe '#initialize' do
    it 'creates italic with content' do
      italic = described_class.new(content: 'emphasized text')

      expect(italic.content).to eq('emphasized text')
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Monospace do
  describe '#initialize' do
    it 'creates monospace with content' do
      mono = described_class.new(content: 'code')

      expect(mono.content).to eq('code')
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Link do
  describe '#initialize' do
    it 'creates link with path' do
      link = described_class.new(path: 'https://example.com')

      expect(link.path).to eq('https://example.com')
    end

    it 'creates link with path and name' do
      link = described_class.new(path: 'https://example.com', name: 'Example')

      expect(link.path).to eq('https://example.com')
      expect(link.name).to eq('Example')
    end
  end
end
