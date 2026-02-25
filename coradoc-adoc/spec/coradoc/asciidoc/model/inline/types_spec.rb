# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Inline::CrossReference do
  describe '.new' do
    it 'creates a cross reference with href' do
      xref = described_class.new(href: 'section-id')

      expect(xref.href).to eq('section-id')
    end

    it 'creates a cross reference with args' do
      xref = described_class.new(href: 'section-id', args: ['Section Title'])

      expect(xref.href).to eq('section-id')
      expect(xref.args).to eq(['Section Title'])
    end

    it 'creates an empty cross reference' do
      xref = described_class.new

      expect(xref.href).to be_nil
      expect(xref.args).to be_nil.or be_empty
    end
  end

  describe '#href' do
    it 'can be set and retrieved' do
      xref = described_class.new
      xref.href = 'another-section'

      expect(xref.href).to eq('another-section')
    end
  end

  describe '#args' do
    it 'can be set as array' do
      xref = described_class.new
      xref.args = %w[Title extra]

      expect(xref.args).to contain_exactly('Title', 'extra')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      xref = described_class.new

      expect(xref).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end

    it 'inherits from Base' do
      xref = described_class.new

      expect(xref).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes to AsciiDoc format' do
      xref = described_class.new(href: 'my-section')

      adoc = xref.to_adoc
      expect(adoc).to be_a(String)
      expect(adoc).to include('my-section')
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Footnote do
  describe '.new' do
    it 'creates a footnote with text' do
      footnote = described_class.new(text: 'Additional information')

      expect(footnote.text).to eq('Additional information')
      expect(footnote.id).to be_nil
    end

    it 'creates a footnote reference with id' do
      footnote = described_class.new(id: 'note1')

      expect(footnote.id).to eq('note1')
      expect(footnote.text).to be_nil
    end

    it 'creates a footnote with both text and id' do
      footnote = described_class.new(id: 'note1', text: 'First note')

      expect(footnote.id).to eq('note1')
      expect(footnote.text).to eq('First note')
    end
  end

  describe '#text' do
    it 'can be set and retrieved' do
      footnote = described_class.new
      footnote.text = 'Note content'

      expect(footnote.text).to eq('Note content')
    end
  end

  describe '#id' do
    it 'can be set and retrieved' do
      footnote = described_class.new
      footnote.id = 'fn-123'

      expect(footnote.id).to eq('fn-123')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      footnote = described_class.new

      expect(footnote).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end

    it 'inherits from Base' do
      footnote = described_class.new

      expect(footnote).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes to AsciiDoc format' do
      footnote = described_class.new(text: 'Test note')

      adoc = footnote.to_adoc
      expect(adoc).to be_a(String)
    end
  end
end
