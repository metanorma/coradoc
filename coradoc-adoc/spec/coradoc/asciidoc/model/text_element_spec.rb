# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::TextElement do
  describe '#initialize' do
    it 'creates text element with content' do
      text = described_class.new(content: 'Hello World')

      expect(text.content).to eq('Hello World')
    end

    it 'creates text element with empty content' do
      text = described_class.new(content: '')

      expect(text.content).to eq('')
    end

    it 'creates text element with line break' do
      text = described_class.new(content: 'Line', line_break: "\n")

      expect(text.line_break).to eq("\n")
    end
  end

  describe '#to_s' do
    it 'returns content as string' do
      text = described_class.new(content: 'Hello World')

      expect(text.to_s).to eq('Hello World')
    end
  end

  describe '#to_adoc' do
    it 'serializes simple text' do
      text = described_class.new(content: 'Hello World')

      expect(text.to_adoc).to include('Hello World')
    end
  end

  describe 'escaping' do
    it 'handles special characters' do
      text = described_class.new(content: 'Text with *asterisks*')

      expect(text.content).to eq('Text with *asterisks*')
    end

    it 'handles newlines' do
      text = described_class.new(content: "Line 1\nLine 2")

      expect(text.content).to include("\n")
    end
  end
end
