# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/renderer'

RSpec.describe Coradoc::Html::Renderer, 'list rendering' do
  let(:renderer) { described_class.new }

  it 'renders unordered list as <ul> with <li> items' do
    item1 = CoreModel::ListItem.new(marker: '*', content: 'First')
    item2 = CoreModel::ListItem.new(marker: '*', content: 'Second')
    list = CoreModel::ListBlock.new(marker_type: 'unordered', items: [item1, item2])
    html = renderer.render(list)
    expect(html).to include('<ul')
    expect(html).to include('<li>')
    expect(html).to include('First')
    expect(html).to include('Second')
  end

  it 'renders ordered list as <ol>' do
    item = CoreModel::ListItem.new(marker: '.', content: 'Item 1')
    list = CoreModel::ListBlock.new(marker_type: 'ordered', items: [item])
    html = renderer.render(list)
    expect(html).to include('<ol')
  end

  it 'renders nested list' do
    inner_item = CoreModel::ListItem.new(marker: '**', content: 'Nested item')
    inner_list = CoreModel::ListBlock.new(marker_type: 'unordered', items: [inner_item])
    outer_item = CoreModel::ListItem.new(marker: '*', content: 'Outer item', nested_list: inner_list)
    outer_list = CoreModel::ListBlock.new(marker_type: 'unordered', items: [outer_item])
    html = renderer.render(outer_list)
    expect(html).to include('Outer item')
    expect(html).to include('Nested item')
    expect(html.scan('<ul').size).to eq(2)
  end

  it 'includes list id' do
    item = CoreModel::ListItem.new(content: 'Item')
    list = CoreModel::ListBlock.new(marker_type: 'unordered', id: 'my-list', items: [item])
    html = renderer.render(list)
    expect(html).to include('id="my-list"')
  end
end
