# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/renderer'

RSpec.describe Coradoc::Html::Renderer, 'annotation rendering' do
  let(:renderer) { described_class.new }

  it 'renders NOTE annotation with correct type class' do
    block = CoreModel::AnnotationBlock.new(
      annotation_type: 'note',
      content: [CoreModel::TextContent.new(text: 'This is a note.')]
    )
    html = renderer.render(block)
    expect(html).to include('admonitionblock')
    expect(html).to include('note')
    expect(html).to include('This is a note.')
  end

  it 'renders WARNING annotation' do
    block = CoreModel::AnnotationBlock.new(
      annotation_type: 'warning',
      content: [CoreModel::TextContent.new(text: 'Danger!')]
    )
    html = renderer.render(block)
    expect(html).to include('warning')
    expect(html).to include('Danger!')
  end

  it 'renders TIP annotation with custom label' do
    block = CoreModel::AnnotationBlock.new(
      annotation_type: 'tip',
      annotation_label: 'Pro Tip',
      content: [CoreModel::TextContent.new(text: 'Use shortcuts')]
    )
    html = renderer.render(block)
    expect(html).to include('Pro Tip')
  end

  it 'includes id when present' do
    block = CoreModel::AnnotationBlock.new(
      annotation_type: 'note',
      id: 'my-note',
      content: [CoreModel::TextContent.new(text: 'Note')]
    )
    html = renderer.render(block)
    expect(html).to include('id="my-note"')
  end
end
