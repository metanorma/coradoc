# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::ElementTransformers::ListTransformer do
  describe '.transform_list' do
    it 'transforms an unordered list' do
      items = [
        Coradoc::AsciiDoc::Model::List::Item.new(
          marker: '*',
          content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Item 1')]
        ),
        Coradoc::AsciiDoc::Model::List::Item.new(
          marker: '*',
          content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Item 2')]
        )
      ]
      list = Coradoc::AsciiDoc::Model::List::Unordered.new(items: items)

      result = described_class.transform_list(list, 'unordered')

      expect(result).to be_a(Coradoc::CoreModel::ListBlock)
      expect(result.marker_type).to eq('unordered')
      expect(result.items.size).to eq(2)
      expect(result.items[0]).to be_a(Coradoc::CoreModel::ListItem)
      expect(result.items[0].content).to eq('Item 1')
      expect(result.items[1].content).to eq('Item 2')
    end

    it 'transforms an ordered list with nested list' do
      nested_items = [
        Coradoc::AsciiDoc::Model::List::Item.new(
          marker: '**',
          content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Nested')]
        )
      ]
      nested_list = Coradoc::AsciiDoc::Model::List::Unordered.new(items: nested_items)

      item = Coradoc::AsciiDoc::Model::List::Item.new(
        marker: '.',
        content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Outer')],
        nested: nested_list
      )
      list = Coradoc::AsciiDoc::Model::List::Ordered.new(items: [item])

      result = described_class.transform_list(list, 'ordered')

      expect(result).to be_a(Coradoc::CoreModel::ListBlock)
      expect(result.marker_type).to eq('ordered')
      expect(result.items.size).to eq(1)

      outer_item = result.items[0]
      expect(outer_item.content).to eq('Outer')
      expect(outer_item.children.last).to be_a(Coradoc::CoreModel::ListBlock)
      expect(outer_item.children.last.marker_type).to eq('unordered')
      expect(outer_item.children.last.items[0].content).to eq('Nested')
    end

    it 'transforms a list item with inline markup' do
      item = Coradoc::AsciiDoc::Model::List::Item.new(
        marker: '*',
        content: [
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'Hello '),
          Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold')
        ]
      )
      list = Coradoc::AsciiDoc::Model::List::Unordered.new(items: [item])

      result = described_class.transform_list(list, 'unordered')

      li = result.items.first
      expect(li.content).to match(/Hello\s+bold/)
      expect(li.children).to be_an(Array)
      expect(li.children.size).to eq(2)
      expect(li.children[1]).to be_a(Coradoc::CoreModel::BoldElement)
      expect(li.children[1].content).to eq('bold')
    end

    it 'transforms a definition list' do
      item = Coradoc::AsciiDoc::Model::List::DefinitionItem.new(
        id: 'def-1',
        terms: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Term 1')],
        contents: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Definition 1')]
      )
      list = Coradoc::AsciiDoc::Model::List::Definition.new(items: [item])

      result = described_class.transform_list(list, 'definition')

      expect(result).to be_a(Coradoc::CoreModel::DefinitionList)
      expect(result.items.size).to eq(1)
      expect(result.items[0]).to be_a(Coradoc::CoreModel::DefinitionItem)
      expect(result.items[0].id).to eq('def-1')
      expect(result.items[0].term).to eq('Term 1')
      expect(result.items[0].definitions.first).to include('Definition 1')
      expect(result.items[0].term_children).not_to be_empty
      expect(result.items[0].definition_children).not_to be_empty
    end

    it 'handles empty lists' do
      list = Coradoc::AsciiDoc::Model::List::Unordered.new(items: [])

      result = described_class.transform_list(list, 'unordered')

      expect(result).to be_a(Coradoc::CoreModel::ListBlock)
      expect(result.items).to be_empty
    end
  end
end
