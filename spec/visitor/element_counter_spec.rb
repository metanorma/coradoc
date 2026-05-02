# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Visitor::ElementCounter do
  it 'counts element types by element_type attribute' do
    doc = Coradoc::CoreModel::StructuralElement.new(
      element_type: 'document',
      children: [
        Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'A'),
        Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'B'),
        Coradoc::CoreModel::AnnotationBlock.new(annotation_type: 'note', content: 'C')
      ]
    )

    counter = described_class.new
    counter.visit(doc)

    expect(counter.to_h).to include('paragraph' => 2, 'annotation_block' => 1)
  end

  it 'falls back to class-derived key when element_type is nil' do
    doc = Coradoc::CoreModel::StructuralElement.new(
      element_type: 'document',
      children: [
        Coradoc::CoreModel::Image.new(src: 'test.png')
      ]
    )

    counter = described_class.new
    counter.visit(doc)

    expect(counter.to_h).to have_key('image')
  end

  it 'excludes zero counts' do
    counter = described_class.new
    expect(counter.to_h).to eq({})
  end

  it 'counts nested elements recursively' do
    doc = Coradoc::CoreModel::StructuralElement.new(
      element_type: 'document',
      children: [
        Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          level: 1,
          children: [
            Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'A')
          ]
        )
      ]
    )

    counter = described_class.new
    counter.visit(doc)

    expect(counter.to_h['document']).to eq(1)
    expect(counter.to_h['section']).to eq(1)
    expect(counter.to_h['paragraph']).to eq(1)
  end
end
