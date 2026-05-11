# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::IdGenerator do
  describe '.generate_from_title' do
    it 'generates ID from simple title' do
      expect(described_class.generate_from_title('Introduction')).to eq('_introduction')
    end

    it 'handles multi-word titles' do
      expect(described_class.generate_from_title('Design Principles')).to eq('_design_principles')
    end

    it 'strips non-alphanumeric characters' do
      expect(described_class.generate_from_title('Section "A" (revised)')).to eq('_section_a_revised')
    end

    it 'returns nil for nil input' do
      expect(described_class.generate_from_title(nil)).to be_nil
    end

    it 'returns nil for blank input' do
      expect(described_class.generate_from_title('')).to be_nil
      expect(described_class.generate_from_title('   ')).to be_nil
    end

    it 'handles special characters' do
      expect(described_class.generate_from_title('ISO/IEC 12345-1')).to eq('_isoiec_123451')
    end
  end
end
