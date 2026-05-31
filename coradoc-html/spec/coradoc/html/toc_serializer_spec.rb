# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/toc_serializer'

RSpec.describe Coradoc::Html::TocSerializer do
  let(:serializer) { described_class.new }

  describe '#build_json' do
    it 'returns empty structure for non-structural elements' do
      block = CoreModel::Block.new
      result = serializer.build_json(block, {})
      expect(result).to eq({ entries: [], numbered: false })
    end

    it 'returns empty entries for document without children' do
      doc = CoreModel::DocumentElement.new
      result = serializer.build_json(doc, {})
      expect(result[:entries]).to eq([])
      expect(result[:numbered]).to be false
    end

    it 'serializes sections with numbered: true when sectnums is set' do
      section = CoreModel::SectionElement.new(
        id: 's1',
        title: 'Section One',
        level: 1
      )
      doc = CoreModel::DocumentElement.new(children: [section])

      result = serializer.build_json(doc, { section_numbers: true })
      expect(result[:numbered]).to be true
      expect(result[:entries].size).to eq(1)
      expect(result[:entries][0][:id]).to eq('s1')
      expect(result[:entries][0][:title]).to eq('Section One')
    end

    it 'serializes nested entries' do
      child = CoreModel::SectionElement.new(id: 's1-1', title: 'Sub', level: 2)
      section = CoreModel::SectionElement.new(
        id: 's1',
        title: 'Parent',
        level: 1,
        children: [child]
      )
      doc = CoreModel::DocumentElement.new(children: [section])

      result = serializer.build_json(doc, { toc_levels: 2 })
      entry = result[:entries][0]
      expect(entry[:children].size).to eq(1)
      expect(entry[:children][0][:id]).to eq('s1-1')
    end

    it 'respects toclevels option' do
      grandchild = CoreModel::SectionElement.new(id: 's1-1-1', title: 'Deep', level: 3)
      child = CoreModel::SectionElement.new(id: 's1-1', title: 'Sub', level: 2, children: [grandchild])
      section = CoreModel::SectionElement.new(id: 's1', title: 'Parent', level: 1, children: [child])
      doc = CoreModel::DocumentElement.new(children: [section])

      result = serializer.build_json(doc, { toc_levels: 1 })
      entry = result[:entries][0]
      expect(entry[:children]).to eq([])
    end

    it 'uses TocBuilder.from_options for option normalization' do
      section = CoreModel::SectionElement.new(id: 's1', title: 'Test', level: 1)
      doc = CoreModel::DocumentElement.new(children: [section])

      result = serializer.build_json(doc, { section_numbers: true, section_number_levels: 1, toc_levels: 3 })
      expect(result[:entries][0][:number]).to eq('1')
    end
  end
end
