# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::ToCoreModelRegistrations do
  describe '.register_all!' do
    # Use a fresh registry for these tests
    before do
      Coradoc::AsciiDoc::Transform::Registry.clear
    end

    after do
      Coradoc::AsciiDoc::Transform::Registry.clear
      # Re-register defaults for other tests
      described_class.register_all!
    end

    it 'registers Document transformer' do
      described_class.register_all!

      expect(Coradoc::AsciiDoc::Transform::Registry.registered?(
               Coradoc::AsciiDoc::Model::Document
             )).to be true
    end

    it 'registers Section transformer' do
      described_class.register_all!

      expect(Coradoc::AsciiDoc::Transform::Registry.registered?(
               Coradoc::AsciiDoc::Model::Section
             )).to be true
    end

    it 'registers Paragraph transformer' do
      described_class.register_all!

      expect(Coradoc::AsciiDoc::Transform::Registry.registered?(
               Coradoc::AsciiDoc::Model::Paragraph
             )).to be true
    end

    it 'registers Block::Core transformer' do
      described_class.register_all!

      expect(Coradoc::AsciiDoc::Transform::Registry.registered?(
               Coradoc::AsciiDoc::Model::Block::Core
             )).to be true
    end

    it 'registers specific block types with priority' do
      described_class.register_all!

      # Check that specific block types are registered
      [
        Coradoc::AsciiDoc::Model::Block::SourceCode,
        Coradoc::AsciiDoc::Model::Block::Quote,
        Coradoc::AsciiDoc::Model::Block::Example,
        Coradoc::AsciiDoc::Model::Block::Side,
        Coradoc::AsciiDoc::Model::Block::Literal,
        Coradoc::AsciiDoc::Model::Block::Open,
        Coradoc::AsciiDoc::Model::Block::Pass
      ].each do |block_class|
        expect(Coradoc::AsciiDoc::Transform::Registry.registered?(block_class)).to be true
      end
    end

    it 'registers list types' do
      described_class.register_all!

      [
        Coradoc::AsciiDoc::Model::List::Unordered,
        Coradoc::AsciiDoc::Model::List::Ordered,
        Coradoc::AsciiDoc::Model::List::Definition
      ].each do |list_class|
        expect(Coradoc::AsciiDoc::Transform::Registry.registered?(list_class)).to be true
      end
    end

    it 'registers inline element types' do
      described_class.register_all!

      [
        Coradoc::AsciiDoc::Model::Inline::Bold,
        Coradoc::AsciiDoc::Model::Inline::Italic,
        Coradoc::AsciiDoc::Model::Inline::Monospace,
        Coradoc::AsciiDoc::Model::Inline::Highlight,
        Coradoc::AsciiDoc::Model::Inline::Link
      ].each do |inline_class|
        expect(Coradoc::AsciiDoc::Transform::Registry.registered?(inline_class)).to be true
      end
    end

    it 'registers other model types' do
      described_class.register_all!

      [
        Coradoc::AsciiDoc::Model::Table,
        Coradoc::AsciiDoc::Model::Term,
        Coradoc::AsciiDoc::Model::Admonition,
        Coradoc::AsciiDoc::Model::Image::BlockImage
      ].each do |model_class|
        expect(Coradoc::AsciiDoc::Transform::Registry.registered?(model_class)).to be true
      end
    end

    context 'when transforming via registry' do
      it 'transforms Document using registered transformer' do
        described_class.register_all!

        doc = Coradoc::AsciiDoc::Model::Document.new(id: 'test-doc')
        result = Coradoc::AsciiDoc::Transform::Registry.transform(doc)

        expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
        expect(result.element_type).to eq('document')
        expect(result.id).to eq('test-doc')
      end

      it 'transforms Section using registered transformer' do
        described_class.register_all!

        title = Coradoc::AsciiDoc::Model::Title.new(content: 'Test Section')
        section = Coradoc::AsciiDoc::Model::Section.new(
          id: 'test-section',
          level: 1,
          title: title
        )
        result = Coradoc::AsciiDoc::Transform::Registry.transform(section)

        expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
        expect(result.element_type).to eq('section')
        expect(result.level).to eq(1)
      end

      it 'transforms Inline::Bold using registered transformer' do
        described_class.register_all!

        bold = Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold text')
        result = Coradoc::AsciiDoc::Transform::Registry.transform(bold)

        expect(result).to be_a(Coradoc::CoreModel::InlineElement)
        expect(result.format_type).to eq('bold')
      end
    end

    context 'with custom transformer override' do
      it 'allows custom transformer to override default' do
        described_class.register_all!

        # Register a custom transformer that overrides the default
        custom_transformer = lambda { |model|
          Coradoc::CoreModel::InlineElement.new(
            format_type: 'custom-bold',
            content: "CUSTOM: #{model.content}"
          )
        }
        Coradoc::AsciiDoc::Transform::Registry.register(
          Coradoc::AsciiDoc::Model::Inline::Bold,
          custom_transformer
        )

        bold = Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'text')
        result = Coradoc::AsciiDoc::Transform::Registry.transform(bold)

        expect(result.format_type).to eq('custom-bold')
        expect(result.content).to eq('CUSTOM: text')
      end
    end
  end
end
