# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/document_drop'

RSpec.describe Coradoc::Html::Drop::DocumentDrop do
  describe 'DocumentElement' do
    let(:model) { CoreModel::DocumentElement.new(title: 'My Doc') }
    let(:drop) { described_class.new(model) }

    it_behaves_like 'a liquid drop'

    describe '#template_type' do
      it 'returns document for DocumentElement' do
        expect(drop.template_type).to eq('document')
      end
    end

    describe '#title' do
      it 'returns escaped title' do
        expect(drop.title).to eq('My Doc')
      end
    end

    describe '#structural_type' do
      it 'returns document' do
        expect(drop.structural_type).to eq('document')
      end
    end

    describe '#heading_level' do
      it 'returns 1 for document' do
        expect(drop.heading_level).to eq(1)
      end
    end
  end

  describe 'SectionElement' do
    let(:model) { CoreModel::SectionElement.new(title: 'Intro', level: 1) }
    let(:drop) { described_class.new(model) }

    it_behaves_like 'a liquid drop'

    describe '#template_type' do
      it 'returns section for SectionElement' do
        expect(drop.template_type).to eq('section')
      end
    end

    describe '#heading_level' do
      it 'offsets by +1 (level 1 → h2)' do
        expect(drop.heading_level).to eq(2)
      end

      it 'clamps to 6' do
        section = CoreModel::SectionElement.new(level: 6)
        expect(described_class.new(section).heading_level).to eq(6)
      end
    end

    describe '#structural_type' do
      it 'returns section for SectionElement' do
        expect(drop.structural_type).to eq('section')
      end

      it 'returns header for HeaderElement' do
        header = CoreModel::HeaderElement.new
        expect(described_class.new(header).structural_type).to eq('header')
      end

      it 'returns preamble for PreambleElement' do
        preamble = CoreModel::PreambleElement.new
        expect(described_class.new(preamble).structural_type).to eq('preamble')
      end
    end

    describe 'section numbering' do
      it 'includes section number in title when set' do
        drop.section_number = '2.1'
        expect(drop.title).to eq('2.1. Intro')
      end

      it 'returns plain title without section number' do
        expect(drop.title).to eq('Intro')
      end
    end
  end
end
