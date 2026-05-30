# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html do
  describe '.parse' do
    it 'parses HTML to CoreModel elements' do
      elements = described_class.parse('<h1>Title</h1><p>Content</p>')
      expect(elements).to be_a(Array)
      expect(elements.size).to eq(2)
    end
  end

  describe '.parse_to_core' do
    it 'wraps parsed elements into a DocumentElement' do
      doc = described_class.parse_to_core('<h1>Title</h1><p>Content</p>')
      expect(doc).to be_a(CoreModel::DocumentElement)
    end

    it 'extracts title from first h1 section' do
      doc = described_class.parse_to_core('<h1>My Title</h1><p>Content</p>')
      expect(doc.title).to eq('My Title')
    end

    it 'returns DocumentElement directly when result is already a Base' do
      doc = described_class.parse_to_core('<p>Just a paragraph</p>')
      expect(doc).to be_a(CoreModel::DocumentElement)
    end
  end

  describe '.serialize' do
    it 'serializes a CoreModel document to HTML' do
      doc = CoreModel::DocumentElement.new(title: 'Test', children: [])
      html = described_class.serialize(doc)
      expect(html).to include('Test')
    end
  end

  describe '.serialize_static' do
    it 'delegates to Static converter' do
      doc = CoreModel::DocumentElement.new(title: 'Static', children: [])
      html = described_class.serialize_static(doc)
      expect(html).to include('Static')
    end
  end

  describe '.serialize_as' do
    it 'serializes to static format' do
      doc = CoreModel::DocumentElement.new(title: 'Format', children: [])
      html = described_class.serialize_as(doc, :static)
      expect(html).to include('Format')
    end

    it 'raises for unknown format' do
      doc = CoreModel::DocumentElement.new(children: [])
      expect { described_class.serialize_as(doc, :unknown) }.to raise_error(ArgumentError, /Unknown output format/)
    end
  end

  describe '.validate_core_model!' do
    it 'passes for CoreModel types' do
      doc = CoreModel::DocumentElement.new(children: [])
      expect(described_class.validate_core_model!(doc)).to eq(doc)
    end

    it 'raises for non-CoreModel types' do
      expect { described_class.validate_core_model!('not a model') }.to raise_error(ArgumentError, /CoreModel/)
    end

    it 'returns nil for nil input' do
      expect(described_class.validate_core_model!(nil)).to be_nil
    end
  end

  describe '.handles_model?' do
    it 'accepts Nokogiri nodes' do
      doc = Nokogiri::HTML('<p>test</p>')
      expect(described_class.handles_model?(doc)).to be true
    end

    it 'accepts CoreModel types' do
      expect(described_class.handles_model?(CoreModel::Block.new)).to be true
    end

    it 'rejects other types' do
      expect(described_class.handles_model?('string')).to be false
    end
  end
end
