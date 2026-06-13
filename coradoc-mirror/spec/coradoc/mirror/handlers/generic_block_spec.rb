# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Coradoc::Mirror::Handlers::GenericBlock do
  let(:context) { Coradoc::Mirror::CoreModelToMirror.new }

  describe '.call' do
    it 'returns nil if content is empty' do
      block_class = Class.new(Coradoc::CoreModel::Block)
      element = block_class.new

      result = described_class.call(element, context: context)
      expect(result).to be_nil
    end

    it 'creates a generic block node with semantic type' do
      block_class = Class.new(Coradoc::CoreModel::Block) do
        def resolve_semantic_type
          :test_type
        end
      end

      element = block_class.new(
        id: 'block-1',
        title: 'Test Block',
        children: [Coradoc::CoreModel::TextContent.new(text: 'Some text')]
      )

      result = described_class.call(element, context: context)

      expect(result).to be_a(Coradoc::Mirror::Node::GenericBlock)
      expect(result.id).to eq('block-1')
      expect(result.title).to eq('Test Block')
      expect(result.semantic_type).to eq('test_type')
      expect(result.content.length).to eq(1)
      expect(result.content.first.type).to eq('text')
      expect(result.content.first.text).to eq('Some text')
    end

    it 'creates a generic block node without semantic type' do
      block_class = Class.new(Coradoc::CoreModel::Block) do
        def resolve_semantic_type
          nil
        end
      end

      element = block_class.new(
        children: [Coradoc::CoreModel::TextContent.new(text: 'Some text')]
      )

      result = described_class.call(element, context: context)

      expect(result).to be_a(Coradoc::Mirror::Node::GenericBlock)
      expect(result.id).to be_nil
      expect(result.title).to be_nil
      expect(result.semantic_type).to be_nil
    end
  end
end
