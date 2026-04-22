# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Section do
  describe '#initialize' do
    it 'creates section with default values' do
      section = described_class.new

      expect(section.id).to be_nil
      expect(section.title).to be_nil
      expect(section.contents).to eq([])
      expect(section.sections).to eq([])
    end

    it 'accepts custom title' do
      title = Coradoc::AsciiDoc::Model::Title.new(content: 'Introduction', level_int: 1)
      section = described_class.new(title: title)

      expect(section.title).to eq(title)
      expect(section.title.to_s).to eq('Introduction')
    end

    it 'accepts level directly' do
      section = described_class.new(level: 2)

      expect(section.level).to eq(2)
      expect(section.title.level_int).to eq(2)
    end

    it 'accepts custom id' do
      section = described_class.new(id: 'intro')

      expect(section.id).to eq('intro')
    end

    it 'accepts custom contents' do
      paragraph = Coradoc::AsciiDoc::Model::Paragraph.new(
        content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Some text')]
      )
      section = described_class.new(contents: [paragraph])

      expect(section.contents).to eq([paragraph])
    end

    it 'accepts nested sections' do
      nested = described_class.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Nested', level_int: 2)
      )
      section = described_class.new(sections: [nested])

      expect(section.sections).to eq([nested])
    end
  end

  describe '#level' do
    it 'returns level from title' do
      title = Coradoc::AsciiDoc::Model::Title.new(content: 'Section', level_int: 3)
      section = described_class.new(title: title)

      expect(section.level).to eq(3)
    end

    it 'returns nil when title is nil' do
      section = described_class.new

      expect(section.level).to be_nil
    end
  end

  describe '#level=' do
    it 'sets level on existing title' do
      title = Coradoc::AsciiDoc::Model::Title.new(content: 'Section', level_int: 1)
      section = described_class.new(title: title)

      section.level = 2
      expect(section.level).to eq(2)
      expect(title.level_int).to eq(2)
    end

    it 'creates title when nil' do
      section = described_class.new

      section.level = 1
      expect(section.title).to be_a(Coradoc::AsciiDoc::Model::Title)
      expect(section.level).to eq(1)
    end
  end

  describe '#safe_to_collapse?' do
    it 'returns true when title is nil and sections empty' do
      section = described_class.new

      expect(section.safe_to_collapse?).to be true
    end

    it 'returns false when title is present' do
      section = described_class.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Section', level_int: 1)
      )

      expect(section.safe_to_collapse?).to be false
    end

    it 'returns false when sections present' do
      nested = described_class.new
      section = described_class.new(sections: [nested])

      expect(section.safe_to_collapse?).to be false
    end
  end

  describe 'validation' do
    it 'validates title type' do
      section = described_class.new(title: 'Invalid Title')

      expect { section.validate }.to raise_error(TypeError)
    end

    it 'accepts Title object' do
      title = Coradoc::AsciiDoc::Model::Title.new(content: 'Valid', level_int: 1)
      section = described_class.new(title: title)

      expect { section.validate }.not_to raise_error
    end

    it 'accepts nil title' do
      section = described_class.new(title: nil)

      expect { section.validate }.not_to raise_error
    end
  end
end
