# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc do
  describe '.registry' do
    it 'returns a Registry instance' do
      expect(described_class.registry).to be_a(Coradoc::Registry)
    end

    it 'returns the same registry instance on subsequent calls' do
      registry1 = described_class.registry
      registry2 = described_class.registry
      expect(registry1).to eq(registry2)
    end
  end

  describe '.register_format' do
    it 'registers a format module' do
      test_module = Module.new
      described_class.register_format(:test_format, test_module)
      expect(described_class.registered_formats).to include(:test_format)
      expect(described_class.get_format(:test_format)).to eq(test_module)
    end

    it 'registers a format with options' do
      test_module = Module.new
      described_class.register_format(:test_format_with_opts, test_module, extensions: [:custom])
      expect(described_class.registered_formats).to include(:test_format_with_opts)
    end
  end

  describe '.get_format' do
    it 'returns the format module for a registered format' do
      expect(described_class.get_format(:html)).to eq(Coradoc::Html)
    end

    it 'returns nil for an unregistered format' do
      expect(described_class.get_format(:nonexistent)).to be_nil
    end
  end

  describe '.registered_formats' do
    it 'returns an array of registered format names' do
      formats = described_class.registered_formats
      expect(formats).to be_an(Array)
      expect(formats).to include(:html)
      expect(formats).to include(:markdown)
    end
  end

  describe '.parse' do
    context 'with Markdown format' do
      it 'parses Markdown text to CoreModel' do
        markdown_text = "# Title\n\nParagraph content"
        result = described_class.parse(markdown_text, format: :markdown)

        expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
      end
    end

    context 'with unregistered format' do
      it 'raises UnsupportedFormatError' do
        expect do
          described_class.parse('text', format: :unknown)
        end.to raise_error(Coradoc::UnsupportedFormatError, /not registered/)
      end
    end
  end

  describe '.convert' do
    it 'converts between formats' do
      markdown_text = "# Title\n\nParagraph"
      result = described_class.convert(markdown_text, from: :markdown, to: :html)

      expect(result).to be_a(String)
      expect(result).to include('<!DOCTYPE html>')
    end
  end

  describe '.to_core' do
    it 'transforms Markdown model to CoreModel' do
      md_doc = Coradoc::Markdown.parse("# Title\n\nContent")
      core = described_class.to_core(md_doc)

      expect(core).to be_a(Coradoc::CoreModel::StructuralElement)
    end

    it 'returns CoreModel as-is' do
      core = Coradoc::CoreModel::StructuralElement.new(element_type: 'document')
      result = described_class.to_core(core)

      expect(result).to eq(core)
    end
  end

  describe '.serialize' do
    it 'serializes CoreModel to HTML' do
      core = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Test')
        ]
      )

      result = described_class.serialize(core, to: :html)
      expect(result).to be_a(String)
      expect(result).to include('<!DOCTYPE html>')
    end

    it 'raises error for unregistered format' do
      core = Coradoc::CoreModel::StructuralElement.new(element_type: 'document')

      expect do
        described_class.serialize(core, to: :unknown)
      end.to raise_error(Coradoc::UnsupportedFormatError)
    end
  end

  describe 'error classes' do
    it 'defines base Error class' do
      expect(Coradoc::Error).to be < StandardError
    end

    it 'defines ValidationError' do
      expect(Coradoc::ValidationError).to be < Coradoc::Error
    end

    it 'defines TransformationError' do
      expect(Coradoc::TransformationError).to be < Coradoc::Error
    end

    it 'defines UnsupportedFormatError' do
      expect(Coradoc::UnsupportedFormatError).to be < Coradoc::Error
    end
  end
end
