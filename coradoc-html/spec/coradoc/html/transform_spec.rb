# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe Coradoc::Html::Transform::ToCoreModel do
  describe '.transform' do
    it 'transforms a Nokogiri document to CoreModel elements' do
      doc = Nokogiri::HTML('<p>Hello world</p>')
      result = described_class.transform(doc)

      aggregate_failures do
        expect(result).to be_a(Array)
        expect(result).not_to be_empty
        expect(result.first).to be_a(Coradoc::CoreModel::Base)
      end
    end

    it 'transforms a Nokogiri node to CoreModel' do
      doc = Nokogiri::HTML('<h1>Title</h1>')
      node = doc.at('h1')
      result = described_class.transform(node)

      expect(result).to be_a(Coradoc::CoreModel::Base)
    end

    it 'passes through CoreModel unchanged' do
      core = Coradoc::CoreModel::StructuralElement.new(element_type: 'document')
      result = described_class.transform(core)

      expect(result).to equal(core)
    end

    it 'transforms arrays element-wise' do
      doc1 = Nokogiri::HTML('<p>First</p>')
      doc2 = Nokogiri::HTML('<p>Second</p>')
      result = described_class.transform([doc1, doc2])

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end
  end
end

RSpec.describe Coradoc::Html::Transform::FromCoreModel do
  describe '.transform' do
    it 'transforms CoreModel to HTML string' do
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test'
      )
      result = described_class.transform(doc)

      expect(result).to be_a(String)
      expect(result).to include('<')
    end

    it 'transforms arrays by joining' do
      elements = [
        Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'A'),
        Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'B')
      ]
      result = described_class.transform(elements)

      expect(result).to be_a(String)
    end
  end
end

RSpec.describe Coradoc::Html, '#handles_model?' do
  it 'handles Nokogiri::XML::Document' do
    doc = Nokogiri::HTML('<p>test</p>')
    expect(described_class.handles_model?(doc)).to be true
  end

  it 'handles Nokogiri::XML::Node' do
    doc = Nokogiri::HTML('<p>test</p>')
    expect(described_class.handles_model?(doc.at('p'))).to be true
  end

  it 'handles CoreModel::Base' do
    core = Coradoc::CoreModel::StructuralElement.new(element_type: 'document')
    expect(described_class.handles_model?(core)).to be true
  end

  it 'does not handle strings' do
    expect(described_class.handles_model?('hello')).to be false
  end
end
