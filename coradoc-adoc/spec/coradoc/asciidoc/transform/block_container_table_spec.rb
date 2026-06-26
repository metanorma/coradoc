# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

RSpec.describe 'Tables nested inside block containers', :asciidoc do
  let(:table_adoc) do
    <<~ADOC
      [cols="1,1"]
      |===
      | A | B
      | 1 | 2
      |===
    ADOC
  end

  def first_child_class(adoc)
    parsed = Coradoc.parse(adoc, format: :asciidoc)
    parsed.children.first
  end

  def child_classes(block)
    Array(block.children).map(&:class)
  end

  def has_child_of_class?(block, klass)
    Array(block.children).any? { |child| child.is_a?(klass) }
  end

  context 'inside an open block (--)' do
    it 'preserves the table as a child of the open block' do
      adoc = "--\n#{table_adoc}\n--\n"
      open_block = first_child_class(adoc)
      expect(open_block).to be_a(Coradoc::CoreModel::OpenBlock)
      table = open_block.children.find { it.is_a?(Coradoc::CoreModel::Table) }
      expect(table).not_to be_nil
    end

    it 'preserves prose and table together' do
      adoc = <<~ADOC
        --
        Intro paragraph.

        #{table_adoc.chomp}

        Outro paragraph.
        --
      ADOC
      open_block = first_child_class(adoc)
      expect(open_block).to be_a(Coradoc::CoreModel::OpenBlock)
      child_classes = open_block.children.map(&:class)
      expect(child_classes).to include(Coradoc::CoreModel::Table)
      expect(child_classes).to include(Coradoc::CoreModel::TextContent)
      expect(child_classes.count).to be(3)
    end

    it 'preserves table alongside list siblings' do
      adoc = <<~ADOC
        --
        * item one
        * item two

        #{table_adoc.chomp}
        --
      ADOC
      open_block = first_child_class(adoc)
      child_classes = open_block.children.map(&:class)
      expect(child_classes).to include(Coradoc::CoreModel::ListBlock)
      expect(child_classes).to include(Coradoc::CoreModel::Table)
    end
  end

  context 'inside an example block (====)' do
    it 'preserves the table as a child' do
      adoc = "====\n#{table_adoc}\n====\n"
      example = first_child_class(adoc)
      expect(example).to be_a(Coradoc::CoreModel::ExampleBlock)
      expect(has_child_of_class?(example, Coradoc::CoreModel::Table)).to be(true)
    end
  end

  context 'inside a sidebar block (****)' do
    it 'preserves the table as a child' do
      adoc = "****\n#{table_adoc}\n****\n"
      sidebar = first_child_class(adoc)
      expect(sidebar).to be_a(Coradoc::CoreModel::SidebarBlock)
      expect(has_child_of_class?(sidebar, Coradoc::CoreModel::Table)).to be(true)
    end
  end

  context 'inside a quote block (____)' do
    it 'preserves the table as a child' do
      adoc = "____\n#{table_adoc}\n____\n"
      quote = first_child_class(adoc)
      expect(quote).to be_a(Coradoc::CoreModel::QuoteBlock)
      expect(has_child_of_class?(quote, Coradoc::CoreModel::Table)).to be(true)
    end
  end

  context 'regression: top-level tables' do
    it 'still parses a top-level table' do
      table = first_child_class(table_adoc)
      expect(table).to be_a(Coradoc::CoreModel::Table)
    end
  end

  context 'round-trip through mirror JSON' do
    it 'preserves the table inside an open block in the serialized output' do
      require 'coradoc-mirror'
      adoc = "--\n#{table_adoc}\n--\n"
      json = JSON.parse(Coradoc.serialize(Coradoc.parse(adoc, format: :asciidoc), to: :mirror_json))
      expect(json.dig('content', 0, 'type')).to eq('open_block')
      inner_types = (json.dig('content', 0, 'content') || []).map { _1['type'] }
      expect(inner_types).to include('table')
    end
  end
end
