# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Mirror::Mark do
  describe 'construction' do
    it 'creates a mark with type' do
      mark = described_class.new
      expect(mark.type).to eq('mark')
    end

    it 'uses PM_TYPE as default type' do
      mark = described_class.new
      expect(mark.type).to eq('mark')
    end
  end

  describe 'serialization' do
    it 'serializes to hash' do
      mark = Coradoc::Mirror::Mark::Bold.new
      expect(mark.to_h).to eq({ 'type' => 'strong' })
    end

    it 'includes attrs when present' do
      mark = Coradoc::Mirror::Mark::Link.new(href: 'https://example.com')
      expect(mark.to_h).to eq({
                                'type' => 'link',
                                'attrs' => { 'href' => 'https://example.com' }
                              })
    end
  end

  describe 'deserialization' do
    it 'reconstructs from hash' do
      hash = { 'type' => 'strong' }
      mark = described_class.from_h(hash)
      expect(mark).to be_a(Coradoc::Mirror::Mark::Bold)
    end

    it 'returns nil for nil input' do
      expect(described_class.from_h(nil)).to be_nil
    end

    it 'handles unknown types as generic Mark' do
      hash = { 'type' => 'custom_mark' }
      mark = described_class.from_h(hash)
      expect(mark).to be_a(described_class)
      expect(mark.type).to eq('custom_mark')
    end

    it 'deserializes link with href' do
      hash = {
        'type' => 'link',
        'attrs' => { 'href' => 'https://example.com' }
      }
      mark = described_class.from_h(hash)
      expect(mark).to be_a(Coradoc::Mirror::Mark::Link)
    end
  end

  describe 'mark type subclasses' do
    it 'registers all subclasses in MARKS map' do
      marks = described_class::MARKS
      expect(marks['strong']).to eq(Coradoc::Mirror::Mark::Bold)
      expect(marks['emphasis']).to eq(Coradoc::Mirror::Mark::Italic)
      expect(marks['code']).to eq(Coradoc::Mirror::Mark::Monospace)
      expect(marks['link']).to eq(Coradoc::Mirror::Mark::Link)
      expect(marks['xref']).to eq(Coradoc::Mirror::Mark::CrossReference)
      expect(marks['highlight']).to eq(Coradoc::Mirror::Mark::Highlight)
      expect(marks['subscript']).to eq(Coradoc::Mirror::Mark::Subscript)
      expect(marks['superscript']).to eq(Coradoc::Mirror::Mark::Superscript)
    end

    it 'Link stores href in attrs' do
      mark = Coradoc::Mirror::Mark::Link.new(href: 'https://example.com')
      expect(mark.href).to eq('https://example.com')
      hash = mark.to_h
      expect(hash['attrs']['href']).to eq('https://example.com')
    end

    it 'CrossReference stores target in attrs' do
      mark = Coradoc::Mirror::Mark::CrossReference.new(target: 'section-1')
      expect(mark.target).to eq('section-1')
    end

    it 'Stem stores stem_type in attrs' do
      mark = Coradoc::Mirror::Mark::Stem.new(stem_type: 'latex')
      expect(mark.stem_type).to eq('latex')
    end
  end
end
