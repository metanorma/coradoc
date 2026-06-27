# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::Cleaner do
  let(:cleaner) { described_class.new }

  describe '#tidy' do
    it 'cleans multiple newlines' do
      input = "Hello\n\n\n\nWorld"
      result = cleaner.tidy(input)
      expect(result).not_to include("\n\n\n")
    end

    it 'handles hash input' do
      input = { 'file1.adoc' => "Hello\n\n\n\nWorld" }
      result = cleaner.tidy(input)
      expect(result['file1.adoc']).not_to include("\n\n\n")
    end
  end

  describe '#remove_newlines' do
    it 'replaces 3+ newlines with 2' do
      result = cleaner.remove_newlines("a\n\n\nb")
      expect(result).to eq("a\n\nb")
    end
  end

  describe '#remove_leading_newlines' do
    it 'removes leading newlines' do
      result = cleaner.remove_leading_newlines("\n\nHello")
      expect(result).to eq('Hello')
    end
  end

  describe '#clean_tag_borders' do
    it 'cleans bracket spacing' do
      result = cleaner.clean_tag_borders('text [ option ] more')
      expect(result).to include('[option]')
    end
  end

  describe '#clean_punctuation_characters' do
    it 'removes space before punctuation after markup' do
      result = cleaner.clean_punctuation_characters('**bold** .')
      expect(result).to eq('**bold**.')
    end
  end

  describe '#remove_block_leading_newlines' do
    it 'removes extra newlines after block open' do
      result = cleaner.remove_block_leading_newlines("]\n****\n\ntext")
      expect(result).to eq("]\n****\ntext")
    end
  end

  describe '#remove_section_attribute_newlines' do
    it 'removes extra newlines between attribute and section' do
      result = cleaner.remove_section_attribute_newlines("]\n\n== Section")
      expect(result).to eq("]\n== Section")
    end
  end

  describe '#preprocess_word_html' do
    it 'scrubs whitespace and cleans headings' do
      input = '<h1>Title</h1><p>Content&nbsp;</p>'
      result = cleaner.preprocess_word_html(input)
      expect(result).to include('Title')
    end
  end
end
