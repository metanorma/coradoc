# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::ChildrenContent do
  describe 'Block with children' do
    it 'returns content when children are empty' do
      block = Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Hello')
      expect(block.renderable_content).to eq('Hello')
    end

    it 'returns content when children are all strings' do
      block = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: 'Plain text',
        children: ['Plain text']
      )
      expect(block.renderable_content).to eq('Plain text')
    end

    it 'returns children when they contain InlineElements' do
      inline = Coradoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'bold')
      block = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        children: ['Text with ', inline, ' word']
      )
      expect(block.renderable_content).to eq(['Text with ', inline, ' word'])
    end
  end

  describe '#flat_text' do
    it 'returns content string when no children' do
      block = Coradoc::CoreModel::Block.new(content: 'Hello world')
      expect(block.flat_text).to eq('Hello world')
    end

    it 'joins string children' do
      block = Coradoc::CoreModel::Block.new(
        content: 'Part one Part two',
        children: ['Part one ', 'Part two']
      )
      expect(block.flat_text).to eq('Part one Part two')
    end

    it 'flattens mixed string and InlineElement children' do
      inline = Coradoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'bold')
      block = Coradoc::CoreModel::Block.new(
        children: ['Text with ', inline, ' word']
      )
      expect(block.flat_text).to eq('Text with bold word')
    end

    it 'returns empty string when everything is nil' do
      block = Coradoc::CoreModel::Block.new
      expect(block.flat_text).to eq('')
    end
  end

  describe 'ListItem with children' do
    it 'returns content when children are all strings' do
      item = Coradoc::CoreModel::ListItem.new(
        marker: '*',
        content: 'Item text',
        children: ['Item text']
      )
      expect(item.renderable_content).to eq('Item text')
    end

    it 'flat_text on ListItem works the same as Block' do
      inline = Coradoc::CoreModel::InlineElement.new(format_type: 'italic', content: 'italic')
      item = Coradoc::CoreModel::ListItem.new(
        marker: '*',
        children: ['Normal ', inline]
      )
      expect(item.flat_text).to eq('Normal italic')
    end
  end

  describe '#to_hash' do
    it 'includes children in hash output' do
      inline = Coradoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'bold')
      block = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: 'Text',
        children: ['Text with ', inline]
      )
      h = block.to_hash
      expect(h).to have_key('children')
      expect(h['children'].length).to eq(2)
    end

    it 'omits children when empty' do
      block = Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Text')
      h = block.to_hash
      expect(h).not_to have_key('children')
    end
  end
end
