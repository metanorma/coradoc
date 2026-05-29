# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/annotation_drop'

RSpec.describe Coradoc::Html::Drop::AnnotationDrop do
  let(:model) do
    CoreModel::AnnotationBlock.new(
      annotation_type: 'note',
      content: [CoreModel::TextContent.new(text: 'This is a note.')]
    )
  end
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#annotation_type' do
    it 'returns the annotation type' do
      expect(drop.annotation_type).to eq('note')
    end

    it 'defaults to note' do
      block = CoreModel::AnnotationBlock.new
      expect(described_class.new(block).annotation_type).to eq('note')
    end
  end

  describe '#label' do
    it 'returns uppercase type when no label' do
      expect(drop.label).to eq('NOTE')
    end

    it 'returns custom label when set' do
      block = CoreModel::AnnotationBlock.new(
        annotation_type: 'warning',
        annotation_label: 'Danger!'
      )
      expect(described_class.new(block).label).to eq('Danger!')
    end
  end

  describe '#css_class' do
    it 'includes admonitionblock and type' do
      expect(drop.css_class).to eq('admonitionblock note')
    end
  end

  describe '#id' do
    it 'returns the model id' do
      block = CoreModel::AnnotationBlock.new(annotation_type: 'tip', id: 'my-tip')
      expect(described_class.new(block).id).to eq('my-tip')
    end
  end
end
