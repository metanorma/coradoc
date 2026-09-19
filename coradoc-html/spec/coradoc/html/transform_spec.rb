# frozen_string_literal: true

require 'spec_helper'
require 'leptris'

RSpec.describe Coradoc::Html::Transform::ToCoreModel do
  describe '.transform' do
    it 'transforms a Leptris document to CoreModel elements' do
      doc = Leptris::HTML.parse('<p>Hello world</p>')
      result = described_class.transform(doc)

      aggregate_failures do
        expect(result).to be_a(Array)
        expect(result).not_to be_empty
        expect(result.first).to be_a(Coradoc::CoreModel::Base)
      end
    end

    it 'transforms a Leptris node to CoreModel' do
      doc = Leptris::HTML.parse('<h1>Title</h1>')
      node = doc.at_css('h1')
      result = described_class.transform(node)

      expect(result).to be_a(Coradoc::CoreModel::Base)
    end

    it 'passes through CoreModel unchanged' do
      core = Coradoc::CoreModel::DocumentElement.new
      result = described_class.transform(core)

      expect(result).to equal(core)
    end

    it 'transforms arrays element-wise' do
      doc1 = Leptris::HTML.parse('<p>First</p>')
      doc2 = Leptris::HTML.parse('<p>Second</p>')
      result = described_class.transform([doc1, doc2])

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end
  end
end

RSpec.describe Coradoc::Html::Transform::FromCoreModel do
  describe '.transform' do
    it 'transforms CoreModel to HTML string' do
      doc = Coradoc::CoreModel::DocumentElement.new(
        title: 'Test'
      )
      result = described_class.transform(doc)

      expect(result).to be_a(String)
      expect(result).to include('<')
    end

    it 'transforms arrays by joining' do
      elements = [
        Coradoc::CoreModel::ParagraphBlock.new(content: 'A'),
        Coradoc::CoreModel::ParagraphBlock.new(content: 'B')
      ]
      result = described_class.transform(elements)

      expect(result).to be_a(String)
    end
  end
end

RSpec.describe Coradoc::Html, '#handles_model?' do
  it 'handles Leptris::XML::Document' do
    doc = Leptris::HTML.parse('<p>test</p>')
    expect(described_class.handles_model?(doc)).to be true
  end

  it 'handles Leptris::XML::Node' do
    doc = Leptris::HTML.parse('<p>test</p>')
    expect(described_class.handles_model?(doc.at('p'))).to be true
  end

  it 'handles CoreModel::Base' do
    core = Coradoc::CoreModel::DocumentElement.new
    expect(described_class.handles_model?(core)).to be true
  end

  it 'does not handle strings' do
    expect(described_class.handles_model?('hello')).to be false
  end
end
