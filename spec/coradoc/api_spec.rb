# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html'
require 'coradoc/markdown'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'Coradoc API' do
  describe '.detect_format' do
    it 'detects AsciiDoc from .adoc extension' do
      expect(Coradoc.detect_format('document.adoc')).to eq(:asciidoc)
    end

    it 'detects AsciiDoc from .asciidoc extension' do
      expect(Coradoc.detect_format('document.asciidoc')).to eq(:asciidoc)
    end

    it 'detects HTML from .html extension' do
      expect(Coradoc.detect_format('page.html')).to eq(:html)
    end

    it 'detects HTML from .htm extension' do
      expect(Coradoc.detect_format('page.htm')).to eq(:html)
    end

    it 'detects Markdown from .md extension' do
      expect(Coradoc.detect_format('readme.md')).to eq(:markdown)
    end

    it 'detects Markdown from .markdown extension' do
      expect(Coradoc.detect_format('doc.markdown')).to eq(:markdown)
    end

    it 'detects Markdown from .mdown extension' do
      expect(Coradoc.detect_format('doc.mdown')).to eq(:markdown)
    end

    it 'detects DOCX from .docx extension' do
      expect(Coradoc.detect_format('report.docx')).to eq(:docx)
    end

    it 'returns nil for unknown extensions' do
      expect(Coradoc.detect_format('file.txt')).to be_nil
    end

    it 'is case-insensitive' do
      expect(Coradoc.detect_format('file.MD')).to eq(:markdown)
      expect(Coradoc.detect_format('file.HTML')).to eq(:html)
    end
  end

  describe '.binary_format?' do
    it 'returns true for :docx' do
      expect(Coradoc.binary_format?(:docx)).to be true
    end

    it 'returns false for :asciidoc' do
      expect(Coradoc.binary_format?(:asciidoc)).to be false
    end

    it 'returns false for :html' do
      expect(Coradoc.binary_format?(:html)).to be false
    end

    it 'returns false for :markdown' do
      expect(Coradoc.binary_format?(:markdown)).to be false
    end
  end

  describe '.parse_file' do
    let(:temp_dir) { Dir.mktmpdir('coradoc_api_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    it 'parses a Markdown file to CoreModel' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, "# Title\n\nContent")

      doc = Coradoc.parse_file(file)

      expect(doc).to be_a(Coradoc::CoreModel::Base)
    end

    it 'auto-detects format from extension' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, "# Hello\n\nWorld")

      doc = Coradoc.parse_file(file)

      expect(doc).to be_a(Coradoc::CoreModel::Base)
    end

    it 'uses explicit format when provided' do
      file = File.join(temp_dir, 'doc.txt')
      File.write(file, "# Title\n\nParagraph")

      doc = Coradoc.parse_file(file, format: :markdown)

      expect(doc).to be_a(Coradoc::CoreModel::Base)
    end

    it 'raises UnsupportedFormatError for unknown extensions without format' do
      file = File.join(temp_dir, 'doc.xyz')
      File.write(file, 'content')

      expect { Coradoc.parse_file(file) }.to raise_error(Coradoc::UnsupportedFormatError)
    end

    it 'raises UnsupportedFormatError for unregistered format' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, 'content')

      expect { Coradoc.parse_file(file, format: :nonexistent) }.to raise_error(Coradoc::UnsupportedFormatError)
    end
  end

  describe '.convert_file' do
    let(:temp_dir) { Dir.mktmpdir('coradoc_api_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    it 'converts a Markdown file to HTML' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, "# Title\n\nParagraph")

      html = Coradoc.convert_file(file, to: :html)

      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('Title')
    end

    it 'converts with explicit source format' do
      file = File.join(temp_dir, 'doc.txt')
      File.write(file, "# Title\n\nParagraph")

      html = Coradoc.convert_file(file, from: :markdown, to: :html)

      expect(html).to include('<!DOCTYPE html>')
    end

    it 'raises UnsupportedFormatError for unknown source format' do
      file = File.join(temp_dir, 'doc.xyz')
      File.write(file, 'content')

      expect { Coradoc.convert_file(file, to: :html) }.to raise_error(Coradoc::UnsupportedFormatError)
    end
  end

  describe 'EXTENSION_FORMATS' do
    it 'maps all supported extensions' do
      expect(Coradoc::EXTENSION_FORMATS).to include(
        '.adoc' => :asciidoc,
        '.asciidoc' => :asciidoc,
        '.docx' => :docx,
        '.html' => :html,
        '.htm' => :html,
        '.md' => :markdown,
        '.markdown' => :markdown,
        '.mdown' => :markdown
      )
    end
  end

  describe 'BINARY_FORMATS' do
    it 'includes docx' do
      expect(Coradoc::BINARY_FORMATS).to include(:docx)
    end

    it 'is frozen' do
      expect(Coradoc::BINARY_FORMATS).to be_frozen
    end
  end
end
