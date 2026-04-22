# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Header do
  describe '#initialize' do
    it 'creates header with title' do
      title = Coradoc::AsciiDoc::Model::Title.new(content: 'My Document', level_int: 0)
      header = described_class.new(title: title)

      expect(header.title).to eq(title)
      expect(header.title.to_s).to eq('My Document')
    end

    it 'creates header with author' do
      author = Coradoc::AsciiDoc::Model::Author.new(
        fullname: 'John Doe',
        email: 'john@example.com'
      )
      header = described_class.new(title: nil, author: author)

      expect(header.author).to eq(author)
    end

    it 'creates header with revision' do
      revision = Coradoc::AsciiDoc::Model::Revision.new(
        number: '1.0',
        date: '2024-01-01'
      )
      header = described_class.new(title: nil, revision: revision)

      expect(header.revision).to eq(revision)
    end

    it 'creates header with id' do
      title = Coradoc::AsciiDoc::Model::Title.new(content: 'Doc')
      header = described_class.new(id: 'main-header', title: title)

      expect(header.id).to eq('main-header')
    end
  end

  describe 'validation' do
    it 'accepts valid author type' do
      author = Coradoc::AsciiDoc::Model::Author.new(fullname: 'John')
      header = described_class.new(title: nil, author: author)

      expect { header.validate }.not_to raise_error
    end

    it 'accepts valid revision type' do
      revision = Coradoc::AsciiDoc::Model::Revision.new(number: '1.0')
      header = described_class.new(title: nil, revision: revision)

      expect { header.validate }.not_to raise_error
    end

    it 'accepts nil author' do
      header = described_class.new(title: nil, author: nil)

      expect { header.validate }.not_to raise_error
    end

    it 'accepts nil revision' do
      header = described_class.new(title: nil, revision: nil)

      expect { header.validate }.not_to raise_error
    end

    it 'rejects invalid author type' do
      header = described_class.new(title: nil, author: 'Invalid')

      expect { header.validate }.to raise_error(TypeError)
    end

    it 'rejects invalid revision type' do
      header = described_class.new(title: nil, revision: 'Invalid')

      expect { header.validate }.to raise_error(TypeError)
    end
  end
end
