# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::ElementTransformers::DocumentTransformer do
  describe '.transform_document' do
    it 'transforms a document with title and attributes' do
      header = Coradoc::AsciiDoc::Model::Header.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'My Document')])
      )
      
      para = Coradoc::AsciiDoc::Model::Paragraph.new(
        content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Content')]
      )
      
      doc = Coradoc::AsciiDoc::Model::Document.new(
        id: 'doc-1',
        header: header,
        sections: [para]
      )
      
      # We mock the attribute extraction since ToCoreModel might not have a proper Document with attribute lists
      # Wait, no doubles! We just let ToCoreModel.extract_document_attributes run.

      result = described_class.transform_document(doc)

      expect(result).to be_a(Coradoc::CoreModel::DocumentElement)
      expect(result.id).to eq('doc-1')
      expect(result.title).to eq('My Document')
      expect(result.children.size).to eq(1)
      expect(result.children[0]).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(result.children[0].content).to eq('Content')
    end

    it 'handles a document without header' do
      doc = Coradoc::AsciiDoc::Model::Document.new(
        sections: [],
        contents: []
      )

      result = described_class.transform_document(doc)

      expect(result).to be_a(Coradoc::CoreModel::DocumentElement)
      expect(result.title).to eq('')
      expect(result.children).to be_empty
    end
  end

  describe '.transform_section' do
    it 'transforms a section with title and nested contents' do
      para = Coradoc::AsciiDoc::Model::Paragraph.new(
        content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Section Content')]
      )
      
      title = Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Section One')])
      
      section = Coradoc::AsciiDoc::Model::Section.new(
        id: 'sec-1',
        level: 1,
        title: title,
        contents: [para],
        sections: []
      )

      result = described_class.transform_section(section)

      expect(result).to be_a(Coradoc::CoreModel::SectionElement)
      expect(result.id).to eq('sec-1')
      expect(result.title).to eq('Section One')
      expect(result.level).to eq(1)
      expect(result.children.size).to eq(1)
      expect(result.children[0]).to be_a(Coradoc::CoreModel::ParagraphBlock)
    end

    it 'transforms a section with nested sections and generates id' do
      inner_title = Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Inner')])
      inner_section = Coradoc::AsciiDoc::Model::Section.new(
        level: 2,
        title: inner_title,
        contents: [],
        sections: []
      )

      outer_title = Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Outer')])
      outer_section = Coradoc::AsciiDoc::Model::Section.new(
        level: 1,
        title: outer_title,
        contents: [],
        sections: [inner_section]
      )

      result = described_class.transform_section(outer_section)

      expect(result).to be_a(Coradoc::CoreModel::SectionElement)
      expect(result.title).to eq('Outer')
      # ID is generated if nil
      expect(result.id).to eq('_outer')
      expect(result.children.size).to eq(1)

      inner_core = result.children[0]
      expect(inner_core).to be_a(Coradoc::CoreModel::SectionElement)
      expect(inner_core.title).to eq('Inner')
      expect(inner_core.id).to eq('_outer_inner')
    end

    it 'propagates [appendix] style into CoreModel attributes' do
      list = Coradoc::AsciiDoc::Model::AttributeList.new
      list.add_positional('appendix')
      section = Coradoc::AsciiDoc::Model::Section.new(
        level: 1,
        title: Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Appendix')]),
        attribute_list: list
      )

      result = described_class.transform_section(section)

      expect(result.attributes).to be_a(Coradoc::CoreModel::Metadata)
      expect(result.attributes['style']).to eq('appendix')
    end

    it 'propagates named role into CoreModel attributes' do
      list = Coradoc::AsciiDoc::Model::AttributeList.new
      list.add_named('role', 'summary')
      section = Coradoc::AsciiDoc::Model::Section.new(
        level: 1,
        title: Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Overview')]),
        attribute_list: list
      )

      result = described_class.transform_section(section)

      expect(result.attributes['role']).to eq('summary')
    end

    it 'leaves attributes nil when section has no attribute list' do
      section = Coradoc::AsciiDoc::Model::Section.new(
        level: 1,
        title: Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Plain')])
      )

      expect(described_class.transform_section(section).attributes).to be_nil
    end
  end
end
