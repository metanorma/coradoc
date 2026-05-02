# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'Coradoc document_info API' do
  let(:temp_dir) { Dir.mktmpdir('coradoc_info_spec') }

  after do
    FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
  end

  it 'returns structured document information' do
    file = File.join(temp_dir, 'doc.md')
    File.write(file, "# My Title\n\nParagraph 1\n\nParagraph 2")

    info = Coradoc.document_info(file)

    expect(info[:format]).to eq(:markdown)
    expect(info[:size]).to be > 0
    expect(info[:lines]).to eq(5)
    expect(info[:title]).to eq('My Title')
    expect(info[:child_count]).to be >= 1
  end

  it 'accepts explicit format option' do
    file = File.join(temp_dir, 'doc.txt')
    File.write(file, "# Title\n\nContent")

    info = Coradoc.document_info(file, format: :markdown)

    expect(info[:format]).to eq(:markdown)
  end

  it 'raises UnsupportedFormatError for unknown extension without format' do
    file = File.join(temp_dir, 'doc.xyz')
    File.write(file, 'content')

    expect { Coradoc.document_info(file) }.to raise_error(Coradoc::UnsupportedFormatError)
  end

  it 'raises FileNotFoundError for missing file' do
    expect { Coradoc.document_info('/nonexistent/file.md') }.to raise_error(Coradoc::FileNotFoundError)
  end

  it 'includes element_counts when document has children' do
    file = File.join(temp_dir, 'doc.md')
    File.write(file, "# Title\n\nParagraph 1\n\nParagraph 2")

    info = Coradoc.document_info(file)

    expect(info[:element_counts]).to be_a(Hash)
    expect(info[:element_counts]).not_to be_empty
  end
end
