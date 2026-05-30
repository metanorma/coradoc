# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Output processors' do
  describe Coradoc::Output::HtmlStatic do
    describe '.processor_id' do
      it 'returns :html_static' do
        expect(described_class.processor_id).to eq(:html_static)
      end
    end

    describe '.processor_match?' do
      it 'matches .html files' do
        expect(described_class.processor_match?('doc.html')).to be true
      end

      it 'matches .htm files' do
        expect(described_class.processor_match?('doc.htm')).to be true
      end

      it 'does not match other extensions' do
        expect(described_class.processor_match?('doc.adoc')).to be false
      end
    end

    describe '.processor_execute' do
      it 'converts documents to static HTML' do
        doc = CoreModel::DocumentElement.new(title: 'Test', children: [])
        result = described_class.processor_execute({ 'test.html' => doc }, {})
        expect(result).to be_a(Hash)
        expect(result['test.html']).to include('Test')
      end
    end
  end

  describe Coradoc::Output::HtmlSpa do
    describe '.processor_id' do
      it 'returns :html_spa' do
        expect(described_class.processor_id).to eq(:html_spa)
      end
    end

    describe '.processor_match?' do
      it 'matches .html files' do
        expect(described_class.processor_match?('doc.html')).to be true
      end
    end
  end

  describe Coradoc::Output::Spa do
    it 'aliases Spa to HtmlSpa' do
      expect(Coradoc::Output::Spa).to eq(Coradoc::Output::HtmlSpa)
    end
  end
end
