# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Break::ThematicBreak do
  describe '.new' do
    it 'creates a thematic break' do
      break_element = described_class.new

      expect(break_element).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      break_element = described_class.new

      expect(break_element).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes to AsciiDoc format' do
      break_element = described_class.new

      adoc = break_element.to_adoc
      expect(adoc).to be_a(String)
    end
  end
end
