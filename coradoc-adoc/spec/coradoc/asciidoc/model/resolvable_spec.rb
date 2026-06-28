require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Resolvable do
  let(:test_class) do
    Class.new(Coradoc::AsciiDoc::Model::Base) do
      include Coradoc::AsciiDoc::Model::Resolvable

      attr_accessor :custom_path

      def reference_path
        custom_path
      end

      def reference_type
        :test
      end
    end
  end

  let(:unimplemented_class) do
    Class.new(Coradoc::AsciiDoc::Model::Base) do
      include Coradoc::AsciiDoc::Model::Resolvable
    end
  end

  describe 'interface requirements' do
    it 'raises NotImplementedError if #reference_path is not defined' do
      expect { unimplemented_class.new.reference_path }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError if #reference_type is not defined' do
      expect { unimplemented_class.new.reference_type }.to raise_error(NotImplementedError)
    end
  end

  describe '#reference_options' do
    it 'returns an empty hash by default' do
      instance = test_class.new
      expect(instance.reference_options).to eq({})
    end
  end

  describe '#local_reference?' do
    it 'returns true for local paths' do
      instance = test_class.new
      instance.custom_path = '/path/to/file.png'
      expect(instance.local_reference?).to be true

      instance.custom_path = 'relative/file.txt'
      expect(instance.local_reference?).to be true
    end

    it 'returns false for remote URLs' do
      instance = test_class.new
      instance.custom_path = 'https://example.com/file.png'
      expect(instance.local_reference?).to be false

      instance.custom_path = 'http://example.com/file'
      expect(instance.local_reference?).to be false

      instance.custom_path = 'ftp://example.com/file'
      expect(instance.local_reference?).to be false
    end

    it 'returns false when path is nil' do
      instance = test_class.new
      instance.custom_path = nil
      expect(instance.local_reference?).to be false
    end
  end

  describe '#remote_reference?' do
    it 'returns opposite of local_reference?' do
      instance = test_class.new
      instance.custom_path = 'https://example.com/file.png'
      expect(instance.remote_reference?).to be true

      instance.custom_path = 'local/file.png'
      expect(instance.remote_reference?).to be false
    end
  end
end
