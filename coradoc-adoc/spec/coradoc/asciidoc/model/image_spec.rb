# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Image do
  describe 'module structure' do
    it 'defines Image module' do
      expect(described_class).to be_a(Module)
    end

    it 'autoloads Core' do
      expect { described_class::Core }.not_to raise_error
      expect(described_class::Core).to be_a(Class)
    end

    it 'autoloads InlineImage' do
      expect { described_class::InlineImage }.not_to raise_error
      expect(described_class::InlineImage).to be_a(Class)
    end

    it 'autoloads BlockImage' do
      expect { described_class::BlockImage }.not_to raise_error
      expect(described_class::BlockImage).to be_a(Class)
    end
  end

  describe Coradoc::AsciiDoc::Model::Image::Core do
    describe '.new' do
      it 'creates an image with all attributes' do
        image = described_class.new(
          id: 'fig1',
          title: 'Sample Image',
          src: 'images/sample.png'
        )

        expect(image.id).to eq('fig1')
        expect(image.title).to eq('Sample Image')
        expect(image.src).to eq('images/sample.png')
      end

      it 'creates an image with minimal attributes' do
        image = described_class.new(src: 'test.jpg')

        expect(image.src).to eq('test.jpg')
        expect(image.id).to be_nil
        expect(image.title).to be_nil
      end
    end

    describe '#src' do
      it 'can be set and retrieved' do
        image = described_class.new
        image.src = '/path/to/image.png'

        expect(image.src).to eq('/path/to/image.png')
      end
    end

    describe '#title' do
      it 'can be set and retrieved' do
        image = described_class.new
        image.title = 'Image Caption'

        expect(image.title).to eq('Image Caption')
      end
    end

    describe '#id' do
      it 'can be set and retrieved' do
        image = described_class.new
        image.id = 'my-image'

        expect(image.id).to eq('my-image')
      end
    end

    describe '#path alias' do
      it 'aliases src' do
        image = described_class.new(src: 'image.png')

        expect(image.path).to eq('image.png')
      end
    end

    describe '#alt alias' do
      it 'aliases title' do
        image = described_class.new(title: 'Alt text')

        expect(image.alt).to eq('Alt text')
      end
    end

    describe '#attributes' do
      it 'has default AttributeList' do
        image = described_class.new

        expect(image.attributes).to be_a(Coradoc::AsciiDoc::Model::AttributeList)
      end
    end

    describe '#to_adoc' do
      it 'returns AsciiDoc representation' do
        image = described_class.new(
          src: 'test.png',
          title: 'Test Image'
        )

        adoc = image.to_adoc
        expect(adoc).to be_a(String)
      end
    end

    describe 'inheritance' do
      it 'inherits from Base' do
        image = described_class.new

        expect(image).to be_a(Coradoc::AsciiDoc::Model::Base)
      end

      it 'includes Anchorable' do
        image = described_class.new

        expect(image).to be_a(Coradoc::AsciiDoc::Model::Anchorable)
      end
    end
  end
end
