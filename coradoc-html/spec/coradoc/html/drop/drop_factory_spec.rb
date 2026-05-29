# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/drop_factory'

RSpec.describe Coradoc::Html::Drop::DropFactory do
  describe '.create' do
    it 'returns nil for nil' do
      expect(described_class.create(nil)).to be_nil
    end

    it 'maps arrays element-wise' do
      models = [
        CoreModel::TextContent.new(text: 'a'),
        CoreModel::TextContent.new(text: 'b')
      ]
      result = described_class.create(models)
      expect(result).to all(be_a(Coradoc::Html::Drop::Base))
      expect(result.size).to eq(2)
    end

    it 'escapes strings' do
      expect(described_class.create('<b>bold</b>')).to eq('&lt;b&gt;bold&lt;/b&gt;')
    end

    it 'converts numbers to strings' do
      expect(described_class.create(42)).to eq('42')
    end

    it 'converts booleans to strings' do
      expect(described_class.create(true)).to eq('true')
      expect(described_class.create(false)).to eq('false')
    end

    describe 'MECE type dispatch' do
      it 'maps AnnotationBlock to AnnotationDrop' do
        model = CoreModel::AnnotationBlock.new(annotation_type: 'note')
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::AnnotationDrop)
      end

      it 'maps Block (paragraph) to BlockDrop' do
        model = CoreModel::Block.new
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::BlockDrop)
      end

      it 'maps ListBlock to ListBlockDrop' do
        model = CoreModel::ListBlock.new(marker_type: 'unordered')
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::ListBlockDrop)
      end

      it 'maps ListItem to ListItemDrop' do
        model = CoreModel::ListItem.new
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::ListItemDrop)
      end

      it 'maps Table to TableDrop' do
        model = CoreModel::Table.new
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::TableDrop)
      end

      it 'maps TableRow to TableRowDrop' do
        model = CoreModel::TableRow.new
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::TableRowDrop)
      end

      it 'maps TableCell to TableCellDrop' do
        model = CoreModel::TableCell.new
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::TableCellDrop)
      end

      it 'maps Image to ImageDrop' do
        model = CoreModel::Image.new(src: 'test.png')
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::ImageDrop)
      end

      it 'maps InlineElement to InlineElementDrop' do
        model = CoreModel::InlineElement.new
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::InlineElementDrop)
      end

      it 'maps BibliographyEntry to BibliographyEntryDrop' do
        model = CoreModel::BibliographyEntry.new
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::BibliographyEntryDrop)
      end

      it 'maps Bibliography to BibliographyDrop' do
        model = CoreModel::Bibliography.new(level: 1)
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::BibliographyDrop)
      end

      it 'maps TocEntry to TocEntryDrop' do
        model = CoreModel::TocEntry.new(title: 'Test', level: 1)
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::TocEntryDrop)
      end

      it 'maps Toc to TocDrop' do
        model = CoreModel::Toc.new
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::TocDrop)
      end

      it 'maps DefinitionItem to DefinitionItemDrop' do
        model = CoreModel::DefinitionItem.new(term: 'Term')
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::DefinitionItemDrop)
      end

      it 'maps DefinitionList to DefinitionListDrop' do
        model = CoreModel::DefinitionList.new
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::DefinitionListDrop)
      end

      it 'maps Term to TermDrop' do
        model = CoreModel::Term.new(text: 'concept')
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::TermDrop)
      end

      it 'maps FootnoteReference to FootnoteDrop' do
        model = CoreModel::FootnoteReference.new(id: '1')
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::FootnoteDrop)
      end

      it 'maps Footnote to FootnoteDrop' do
        model = CoreModel::Footnote.new(id: '1')
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::FootnoteDrop)
      end

      it 'maps TextContent to TextContentDrop' do
        model = CoreModel::TextContent.new(text: 'hello')
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::TextContentDrop)
      end

      it 'maps SectionElement to DocumentDrop' do
        model = CoreModel::SectionElement.new(level: 1)
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::DocumentDrop)
      end

      it 'maps DocumentElement to DocumentDrop' do
        model = CoreModel::DocumentElement.new
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::DocumentDrop)
      end
    end

    describe 'specificity ordering' do
      it 'AnnotationBlock matches AnnotationDrop, not BlockDrop' do
        model = CoreModel::AnnotationBlock.new(annotation_type: 'warning')
        drop = described_class.create(model)
        expect(drop).to be_a(Coradoc::Html::Drop::AnnotationDrop)
        expect(drop).not_to be_a(Coradoc::Html::Drop::BlockDrop)
      end
    end
  end

  describe '.drop_class_for' do
    it 'returns the Drop class for a known type' do
      expect(described_class.drop_class_for(CoreModel::Block.new))
        .to eq(Coradoc::Html::Drop::BlockDrop)
    end

    it 'returns nil for unknown types' do
      expect(described_class.drop_class_for(Object.new)).to be_nil
    end
  end

  describe '.template_type_for' do
    it 'returns the template type string' do
      expect(described_class.template_type_for(CoreModel::Block.new))
        .to eq('block')
    end

    it 'returns nil for unknown types' do
      expect(described_class.template_type_for(Object.new)).to be_nil
    end
  end
end
