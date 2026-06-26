# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'
require 'coradoc/core_model'

RSpec.describe 'CoreModel builder API (Base.build + fluent constructors)' do
  describe 'CoreModel::Base.build' do
    it 'returns a new instance identical to new() when no block is given' do
      built = Coradoc::CoreModel::Base.build(id: 'x', title: 'T')
      direct = Coradoc::CoreModel::Base.new(id: 'x', title: 'T')

      expect(built.id).to eq('x')
      expect(built.title).to eq('T')
      expect(built).to be_a(Coradoc::CoreModel::Base)
      expect(built.semantically_equivalent?(direct)).to be(true)
    end

    it 'yields the instance for in-place mutation' do
      built = Coradoc::CoreModel::TextContent.build(text: 'before') do |tc|
        tc.text = 'after'
      end

      expect(built.text).to eq('after')
    end

    it 'is inherited by every subclass' do
      [Coradoc::CoreModel::DocumentElement,
       Coradoc::CoreModel::ParagraphBlock,
       Coradoc::CoreModel::ListItem,
       Coradoc::CoreModel::ListBlock].each do |klass|
        expect(klass.respond_to?(:build)).to be(true), "#{klass} should respond to build"
      end
    end
  end

  describe 'ListBlock#add_item' do
    it 'appends a ListItem built from the block and returns self for chaining' do
      list = Coradoc::CoreModel::ListBlock.build(marker_type: 'unordered') do |ul|
        result = ul.add_item { |li| li.add_text('first') }
        expect(result).to be(ul)
        ul.add_item { |li| li.add_text('second') }
      end

      expect(list.items.map(&:content).compact).to eq([])
      expect(list.items.length).to eq(2)
      expect(list.items[0].children.map(&:text)).to eq(['first'])
      expect(list.items[1].children.map(&:text)).to eq(['second'])
    end

    it 'picks a sensible default marker based on marker_type' do
      unordered = Coradoc::CoreModel::ListBlock.build(marker_type: 'unordered') do |ul|
        ul.add_item { |li| li.add_text('a') }
      end
      ordered = Coradoc::CoreModel::ListBlock.build(marker_type: 'ordered') do |ol|
        ol.add_item { |li| li.add_text('1') }
      end

      expect(unordered.items.first.marker).to eq('*')
      expect(ordered.items.first.marker).to eq('.')
    end
  end

  describe 'ListItem#add_text and #add_link' do
    it 'appends typed inline nodes to children' do
      item = Coradoc::CoreModel::ListItem.build do |li|
        li.add_text('See ')
        li.add_link('foo.adoc', text: 'Foo')
        li.add_text('.')
      end

      expect(item.children.map(&:class)).to eq([
        Coradoc::CoreModel::TextContent,
        Coradoc::CoreModel::LinkElement,
        Coradoc::CoreModel::TextContent
      ])
      expect(item.children[0].text).to eq('See ')
      expect(item.children[1].target).to eq('foo.adoc')
      expect(item.children[1].content).to eq('Foo')
    end
  end

  describe 'real-world hub-page synthesis (no source-text round-trip)' do
    it 'builds a DocumentElement with frontmatter + intro + bulleted links' do
      children = [
        { slug: 'iso', title: 'ISO' },
        { slug: 'iec', title: 'IEC' }
      ]

      frontmatter = Coradoc::CoreModel::FrontmatterBlock.new(
        data: { 'title' => 'Author Index' }
      )

      list = Coradoc::CoreModel::ListBlock.build(marker_type: 'unordered') do |ul|
        children.each { |c| ul.add_item { |li| li.add_link("./#{c[:slug]}/", text: c[:title]) } }
      end

      intro = Coradoc::CoreModel::ParagraphBlock.new(content: 'Author documentation.')

      doc = Coradoc::CoreModel::DocumentElement.build(
        title: 'Author Index',
        children: [frontmatter, intro, list]
      )

      expect(doc.title).to eq('Author Index')
      expect(doc.children.length).to eq(3)
      expect(doc.children[0]).to be_a(Coradoc::CoreModel::FrontmatterBlock)
      expect(doc.children[1].content).to eq('Author documentation.')

      built_list = doc.children[2]
      expect(built_list.items.length).to eq(2)
      expect(built_list.items[0].children[0].target).to eq('./iso/')
      expect(built_list.items[0].children[0].content).to eq('ISO')
      expect(built_list.items[1].children[0].target).to eq('./iec/')
    end
  end
end
