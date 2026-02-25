# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Auto IDs' do
  describe Coradoc::Markdown::Heading do
    describe '#auto_id' do
      it 'generates a slug from simple text' do
        heading = described_class.new(text: 'Hello World')
        expect(heading.auto_id).to eq('hello-world')
      end

      it 'handles punctuation' do
        heading = described_class.new(text: 'Hello, World!')
        expect(heading.auto_id).to eq('hello-world')
      end

      it 'handles multiple spaces' do
        heading = described_class.new(text: 'Hello    World')
        expect(heading.auto_id).to eq('hello-world')
      end

      it 'handles numbers' do
        heading = described_class.new(text: 'Chapter 1: Introduction')
        expect(heading.auto_id).to eq('chapter-1-introduction')
      end

      it 'handles leading and trailing special chars' do
        heading = described_class.new(text: '--- Hello ---')
        expect(heading.auto_id).to eq('hello')
      end

      it 'handles empty text' do
        heading = described_class.new(text: '')
        expect(heading.auto_id).to eq('')
      end

      it 'handles nil text' do
        heading = described_class.new(text: nil)
        expect(heading.auto_id).to eq('')
      end

      it 'handles only special characters' do
        heading = described_class.new(text: '!!!')
        expect(heading.auto_id).to eq('section')
      end
    end

    describe '#heading_id' do
      it 'returns auto_id when no explicit id is set' do
        heading = described_class.new(text: 'Introduction')
        expect(heading.heading_id).to eq('introduction')
      end

      it 'returns explicit id when set' do
        heading = described_class.new(text: 'Introduction')
        heading.id = 'custom-id'
        expect(heading.heading_id).to eq('custom-id')
      end
    end
  end
end
