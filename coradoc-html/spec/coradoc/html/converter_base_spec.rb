# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Coradoc::Html::ConverterBase do
  let(:document) { Coradoc::CoreModel::StructuralElement.new(element_type: 'document') }

  describe '.new' do
    it 'accepts a document' do
      converter = described_class.new(document)
      expect(converter.document).to eq(document)
    end

    it 'accepts configuration options' do
      converter = described_class.new(document, { key: 'value' })
      expect(converter.config).to eq({ key: 'value' })
    end

    it 'raises error for invalid document type' do
      expect do
        described_class.new('not a document')
      end.to raise_error(Coradoc::Html::ConverterBase::UnsupportedDocumentError)
    end
  end

  describe '#convert' do
    it 'raises NotImplementedError' do
      converter = described_class.new(document)
      expect do
        converter.convert
      end.to raise_error(NotImplementedError, /must implement #convert/)
    end
  end

  describe '#converter_name' do
    it 'returns the converter name' do
      converter = described_class.new(document)
      expect(converter.converter_name).to eq(:converter_base)
    end
  end

  describe '.convert' do
    it 'creates instance and calls convert' do
      # Create a test subclass that implements convert
      test_class = Class.new(described_class) do
        def convert
          '<html>test</html>'
        end
      end

      result = test_class.convert(document)
      expect(result).to eq('<html>test</html>')
    end
  end

  describe '.to_file' do
    it 'writes output to file' do
      test_class = Class.new(described_class) do
        def convert
          '<html>test</html>'
        end
      end

      Tempfile.create(['test', '.html']) do |file|
        path = file.path
        file.close

        test_class.to_file(document, path)
        expect(File.read(path)).to eq('<html>test</html>')
      end
    end

    it 'creates parent directories' do
      test_class = Class.new(described_class) do
        def convert
          '<html>test</html>'
        end
      end

      Dir.mktmpdir do |dir|
        output_path = File.join(dir, 'subdir', 'test.html')

        test_class.to_file(document, output_path)
        expect(File.exist?(output_path)).to be true
        expect(File.read(output_path)).to eq('<html>test</html>')
      end
    end
  end

  describe Coradoc::Html::ConverterBase::ValidationError do
    it 'is a StandardError' do
      expect(described_class).to be < StandardError
    end
  end

  describe Coradoc::Html::ConverterBase::UnsupportedDocumentError do
    it 'is a StandardError' do
      expect(described_class).to be < StandardError
    end
  end
end
