# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::FromCoreModelRegistrations do
  describe '.register_all!' do
    # Use a fresh registry for these tests
    before do
      Coradoc::AsciiDoc::Transform::Registry.clear
    end

    after do
      Coradoc::AsciiDoc::Transform::Registry.clear
      # Re-register defaults for other tests
      Coradoc::AsciiDoc::Transform::ToCoreModelRegistrations.register_all!
      described_class.register_all!
    end

    it 'registers StructuralElement transformer' do
      described_class.register_all!

      expect(Coradoc::AsciiDoc::Transform::Registry.registered?(
               Coradoc::CoreModel::StructuralElement
             )).to be true
    end

    it 'registers Block transformer' do
      described_class.register_all!

      expect(Coradoc::AsciiDoc::Transform::Registry.registered?(
               Coradoc::CoreModel::Block
             )).to be true
    end

    it 'registers AnnotationBlock with priority (before Block)' do
      described_class.register_all!

      expect(Coradoc::AsciiDoc::Transform::Registry.registered?(
               Coradoc::CoreModel::AnnotationBlock
             )).to be true
    end

    it 'registers list types' do
      described_class.register_all!

      [
        Coradoc::CoreModel::ListBlock,
        Coradoc::CoreModel::ListItem
      ].each do |list_class|
        expect(Coradoc::AsciiDoc::Transform::Registry.registered?(list_class)).to be true
      end
    end

    it 'registers other model types' do
      described_class.register_all!

      [
        Coradoc::CoreModel::Table,
        Coradoc::CoreModel::Term,
        Coradoc::CoreModel::InlineElement,
        Coradoc::CoreModel::Image
      ].each do |model_class|
        expect(Coradoc::AsciiDoc::Transform::Registry.registered?(model_class)).to be true
      end
    end

    context 'when transforming via registry' do
      it 'transforms StructuralElement document using registered transformer' do
        described_class.register_all!

        doc = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          id: 'test-doc',
          title: 'Test Document'
        )
        result = Coradoc::AsciiDoc::Transform::Registry.transform(doc)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
        expect(result.id).to eq('test-doc')
      end

      it 'transforms StructuralElement section using registered transformer' do
        described_class.register_all!

        section = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          id: 'test-section',
          level: 1,
          title: 'Test Section'
        )
        result = Coradoc::AsciiDoc::Transform::Registry.transform(section)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Section)
        expect(result.level).to eq(1)
      end

      it 'transforms InlineElement using registered transformer' do
        described_class.register_all!

        inline = Coradoc::CoreModel::InlineElement.new(
          format_type: 'bold',
          content: 'bold text'
        )
        result = Coradoc::AsciiDoc::Transform::Registry.transform(inline)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Inline::Bold)
        expect(result.content).to eq('bold text')
      end

      it 'transforms AnnotationBlock with correct priority' do
        described_class.register_all!

        annotation = Coradoc::CoreModel::AnnotationBlock.new(
          annotation_type: 'note',
          content: 'This is a note'
        )
        result = Coradoc::AsciiDoc::Transform::Registry.transform(annotation)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Admonition)
        expect(result.type).to eq('NOTE')
      end
    end

    context 'with custom transformer override' do
      it 'allows custom transformer to override default' do
        described_class.register_all!

        # Register a custom transformer that overrides the default
        custom_transformer = lambda { |model|
          Coradoc::AsciiDoc::Model::Inline::Italic.new(
            content: "CUSTOM: #{model.content}"
          )
        }
        Coradoc::AsciiDoc::Transform::Registry.register(
          Coradoc::CoreModel::InlineElement,
          custom_transformer
        )

        inline = Coradoc::CoreModel::InlineElement.new(
          format_type: 'bold',
          content: 'text'
        )
        result = Coradoc::AsciiDoc::Transform::Registry.transform(inline)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Inline::Italic)
        expect(result.content).to eq('CUSTOM: text')
      end
    end
  end
end
