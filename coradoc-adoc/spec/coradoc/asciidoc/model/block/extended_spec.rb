# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Block::Listing do
  describe '.new' do
    it 'creates a listing block with default delimiter' do
      listing = described_class.new

      expect(listing.delimiter_char).to eq('-')
      expect(listing.delimiter_len).to eq(4)
    end

    it 'creates a listing block with lines' do
      listing = described_class.new(lines: ['line 1', 'line 2'])

      expect(listing.lines).to contain_exactly('line 1', 'line 2')
    end
  end

  describe 'inheritance' do
    it 'inherits from Block::Core' do
      listing = described_class.new

      expect(listing).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes to AsciiDoc format' do
      listing = described_class.new(lines: ['code here'])

      adoc = listing.to_adoc
      expect(adoc).to be_a(String)
      expect(adoc).to include('----')
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Block::SourceCode do
  describe '.new' do
    it 'creates a source code block with default delimiter' do
      source = described_class.new

      expect(source.delimiter_char).to eq('-')
      expect(source.delimiter_len).to eq(4)
    end

    it 'creates a source code block with language' do
      source = described_class.new(lang: 'ruby')

      expect(source.lang).to eq('ruby')
    end
  end

  describe 'inheritance' do
    it 'inherits from Block::Core' do
      source = described_class.new

      expect(source).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes to AsciiDoc format' do
      source = described_class.new(lines: ['def hello', "  puts 'hi'", 'end'])

      adoc = source.to_adoc
      expect(adoc).to be_a(String)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Block::Side do
  describe '.new' do
    it 'creates a sidebar block with default delimiter' do
      sidebar = described_class.new

      expect(sidebar.delimiter_char).to eq('*')
      expect(sidebar.delimiter_len).to eq(4)
    end
  end

  describe 'inheritance' do
    it 'inherits from Block::Core' do
      sidebar = described_class.new

      expect(sidebar).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes to AsciiDoc format' do
      sidebar = described_class.new(lines: ['Sidebar content'])

      adoc = sidebar.to_adoc
      expect(adoc).to be_a(String)
      expect(adoc).to include('****')
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Block::Literal do
  describe '.new' do
    it 'creates a literal block with default delimiter' do
      literal = described_class.new

      expect(literal.delimiter_char).to eq('.')
      expect(literal.delimiter_len).to eq(4)
    end
  end

  describe 'inheritance' do
    it 'inherits from Block::Core' do
      literal = described_class.new

      expect(literal).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Block::Open do
  describe '.new' do
    it 'creates an open block with default delimiter' do
      open = described_class.new

      expect(open.delimiter_char).to eq('-')
      expect(open.delimiter_len).to eq(2)
    end
  end

  describe 'inheritance' do
    it 'inherits from Block::Core' do
      open = described_class.new

      expect(open).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Block::Pass do
  describe '.new' do
    it 'creates a pass block with default delimiter' do
      pass = described_class.new

      expect(pass.delimiter_char).to eq('+')
      expect(pass.delimiter_len).to eq(4)
    end
  end

  describe 'inheritance' do
    it 'inherits from Block::Core' do
      pass = described_class.new

      expect(pass).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Block::ReviewerComment do
  describe '.new' do
    it 'creates a reviewer comment block' do
      comment = described_class.new

      expect(comment).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
    end
  end

  describe 'inheritance' do
    it 'inherits from Block::Core' do
      comment = described_class.new

      expect(comment).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
    end
  end
end
