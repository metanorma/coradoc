# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Block::Core do
  describe '#initialize' do
    it 'creates block with delimiter' do
      block = described_class.new(delimiter: '----')

      expect(block.delimiter).to eq('----')
    end

    it 'creates block with lines' do
      block = described_class.new(delimiter: '----', lines: ['Line 1', 'Line 2'])

      expect(block.lines).to eq(['Line 1', 'Line 2'])
    end

    it 'creates block with id' do
      block = described_class.new(delimiter: '----', id: 'my-block')

      expect(block.id).to eq('my-block')
    end

    it 'creates block with title' do
      block = described_class.new(delimiter: '----', title: 'My Block')

      expect(block.title).to eq('My Block')
    end

    it 'creates block with attributes' do
      attrs = Coradoc::AsciiDoc::Model::AttributeList.new
      block = described_class.new(delimiter: '----', attributes: attrs)

      expect(block.attributes).to eq(attrs)
    end
  end

  describe 'delimiter types' do
    it 'supports listing delimiter (----)' do
      block = described_class.new(delimiter: '----')

      expect(block.delimiter).to eq('----')
    end

    it 'supports example delimiter (====)' do
      block = described_class.new(delimiter: '====')

      expect(block.delimiter).to eq('====')
    end

    it 'supports quote delimiter (____)' do
      block = described_class.new(delimiter: '____')

      expect(block.delimiter).to eq('____')
    end

    it 'supports sidebar delimiter (****)' do
      block = described_class.new(delimiter: '****')

      expect(block.delimiter).to eq('****')
    end

    it 'supports literal delimiter (....)' do
      block = described_class.new(delimiter: '....')

      expect(block.delimiter).to eq('....')
    end

    it 'supports pass delimiter (++++)' do
      block = described_class.new(delimiter: '++++')

      expect(block.delimiter).to eq('++++')
    end
  end

  describe 'lines handling' do
    it 'accepts empty lines' do
      block = described_class.new(delimiter: '----', lines: [])

      expect(block.lines).to eq([])
    end

    it 'accepts multiple lines' do
      lines = (1..10).map { |i| "Line #{i}" }
      block = described_class.new(delimiter: '----', lines: lines)

      expect(block.lines).to eq(lines)
    end
  end
end
