# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::TitleText do
  describe '.resolve' do
    it 'returns nil for nil' do
      expect(described_class.resolve(nil)).to be_nil
    end

    it 'returns a string unchanged' do
      expect(described_class.resolve('Hello')).to eq('Hello')
    end

    it 'returns empty string for empty string' do
      expect(described_class.resolve('')).to eq('')
    end

    it 'resolves TextContent via text attribute' do
      model = CoreModel::TextContent.new(text: 'Title')
      expect(described_class.resolve(model)).to eq('Title')
    end

    it 'resolves Term via text attribute' do
      model = CoreModel::Term.new(text: 'Defined Term')
      expect(described_class.resolve(model)).to eq('Defined Term')
    end

    it 'resolves InlineElement via content attribute' do
      model = CoreModel::InlineElement.new(content: 'Formatted')
      expect(described_class.resolve(model)).to eq('Formatted')
    end

    it 'joins array elements' do
      expect(described_class.resolve(['Hello ', 'World'])).to eq('Hello World')
    end

    it 'joins array elements with model objects' do
      item = CoreModel::TextContent.new(text: 'styled')
      expect(described_class.resolve(['Prefix ', item])).to eq('Prefix styled')
    end

    it 'uses to_s for unknown types' do
      expect(described_class.resolve(42)).to eq('42')
    end
  end

  describe '.escape' do
    it 'returns nil for nil' do
      expect(described_class.escape(nil)).to be_nil
    end

    it 'escapes HTML in a string title' do
      expect(described_class.escape('<b>Bold</b>')).to eq('&lt;b&gt;Bold&lt;/b&gt;')
    end

    it 'escapes HTML resolved from a model' do
      model = CoreModel::TextContent.new(text: '<script>alert(1)</script>')
      expect(described_class.escape(model)).to eq('&lt;script&gt;alert(1)&lt;/script&gt;')
    end

    it 'escapes HTML from an array of mixed elements' do
      items = ['Hello ', CoreModel::TextContent.new(text: '<world>')]
      expect(described_class.escape(items)).to eq('Hello &lt;world&gt;')
    end

    it 'returns empty string for empty string title' do
      expect(described_class.escape('')).to eq('')
    end
  end
end
