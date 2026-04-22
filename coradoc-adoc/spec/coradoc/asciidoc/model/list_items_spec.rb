# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::List::Item do
  describe '.new' do
    it 'creates a list item with id' do
      item = described_class.new(id: 'item-1')

      expect(item.id).to eq('item-1')
    end

    it 'creates a list item with marker' do
      item = described_class.new(marker: '*')

      expect(item.marker).to eq('*')
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      item = described_class.new

      expect(item).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::List::DefinitionItem do
  describe '.new' do
    it 'creates a definition list item' do
      item = described_class.new

      expect(item).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      item = described_class.new

      expect(item).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::NamedAttribute do
  describe '.new' do
    it 'creates a named attribute' do
      attr = described_class.new

      expect(attr).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      attr = described_class.new

      expect(attr).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end
