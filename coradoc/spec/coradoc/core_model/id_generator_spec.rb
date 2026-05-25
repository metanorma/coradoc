# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::IdGenerator do
  describe '.generate_from_title' do
    it 'generates an underscore-prefixed ID from a title' do
      expect(described_class.generate_from_title('Syntax')).to eq('_syntax')
    end

    it 'replaces spaces with underscores' do
      expect(described_class.generate_from_title('Main file')).to eq('_main_file')
    end

    it 'strips non-alphanumeric characters' do
      expect(described_class.generate_from_title('Offset calculation (偏移計算)')).to eq('_offset_calculation')
    end

    it 'returns nil for nil title' do
      expect(described_class.generate_from_title(nil)).to be_nil
    end

    it 'returns nil for empty title' do
      expect(described_class.generate_from_title('')).to be_nil
      expect(described_class.generate_from_title('   ')).to be_nil
    end

    context 'with parent_id' do
      it 'prepends parent_id to create hierarchical IDs' do
        result = described_class.generate_from_title('Syntax', parent_id: '_inline_markers')
        expect(result).to eq('_inline_markers_syntax')
      end

      it 'works with multi-level parent IDs' do
        result = described_class.generate_from_title('Content integrity',
                                                     parent_id: '_annotation_sections_validation')
        expect(result).to eq('_annotation_sections_validation_content_integrity')
      end

      it 'falls back to simple ID when parent_id is nil' do
        result = described_class.generate_from_title('Syntax', parent_id: nil)
        expect(result).to eq('_syntax')
      end

      it 'falls back to simple ID when parent_id is empty' do
        result = described_class.generate_from_title('Syntax', parent_id: '')
        expect(result).to eq('_syntax')
      end
    end

    context 'uniqueness with parent context' do
      it 'generates different IDs for same-titled sections under different parents' do
        id1 = described_class.generate_from_title('Syntax', parent_id: '_inline_markers')
        id2 = described_class.generate_from_title('Syntax', parent_id: '_annotation_entries')
        expect(id1).not_to eq(id2)
      end
    end
  end
end
