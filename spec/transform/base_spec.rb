# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Transform::Base do
  let(:transformer) { described_class.new }

  describe '#transform' do
    it 'raises NotImplementedError in base class' do
      expect { transformer.transform(Object.new) }.to raise_error(NotImplementedError, /Subclasses must implement/)
    end
  end

  describe 'included Helpers' do
    it 'delegates core_model? to Helpers' do
      block = Coradoc::CoreModel::Block.new(content: 'test')
      expect(transformer.core_model?(block)).to be true
      expect(transformer.core_model?('string')).to be false
    end

    it 'delegates element_type to Helpers' do
      element = Coradoc::CoreModel::StructuralElement.new(element_type: 'section')
      expect(transformer.element_type(element)).to eq('section')
    end

    it 'delegates transform_collection to Helpers' do
      expect(transformer.transform_collection(nil)).to eq([])
    end
  end
end
