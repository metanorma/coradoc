# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Admonition do
  describe '#initialize' do
    it 'creates admonition with type' do
      adm = described_class.new(type: 'NOTE')

      expect(adm.type).to eq('NOTE')
    end

    it 'creates admonition with content' do
      adm = described_class.new(type: 'NOTE', content: 'This is a note')

      expect(adm.content).to eq('This is a note')
    end

    it 'creates admonition with line_break' do
      adm = described_class.new(type: 'NOTE', line_break: "\n")

      expect(adm.line_break).to eq("\n")
    end
  end

  describe 'standard types' do
    it 'supports NOTE type' do
      adm = described_class.new(type: 'NOTE')

      expect(adm.type).to eq('NOTE')
    end

    it 'supports TIP type' do
      adm = described_class.new(type: 'TIP')

      expect(adm.type).to eq('TIP')
    end

    it 'supports WARNING type' do
      adm = described_class.new(type: 'WARNING')

      expect(adm.type).to eq('WARNING')
    end

    it 'supports CAUTION type' do
      adm = described_class.new(type: 'CAUTION')

      expect(adm.type).to eq('CAUTION')
    end

    it 'supports IMPORTANT type' do
      adm = described_class.new(type: 'IMPORTANT')

      expect(adm.type).to eq('IMPORTANT')
    end
  end

  describe 'content handling' do
    it 'accepts string content' do
      adm = described_class.new(type: 'NOTE', content: 'Simple string')

      expect(adm.content).to eq('Simple string')
    end

    it 'can have empty content' do
      adm = described_class.new(type: 'NOTE')

      expect(adm.content).to be_nil
    end
  end
end
