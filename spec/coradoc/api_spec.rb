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

    it 'raises FileNotFoundError for missing file' do
      expect { Coradoc.parse_file('/nonexistent/file.md') }.to raise_error(Coradoc::FileNotFoundError)
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

  describe '.convert' do
    it 'converts Markdown text to HTML' do
      html = Coradoc.convert("# Hello\n\nWorld", from: :markdown, to: :html)
      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('Hello')
    end

    it 'raises UnsupportedFormatError for unregistered source' do
      expect { Coradoc.convert('text', from: :nonexistent, to: :html) }.to raise_error(Coradoc::UnsupportedFormatError)
    end

    it 'raises UnsupportedFormatError for unregistered target' do
      expect { Coradoc.convert('text', from: :markdown, to: :nonexistent) }.to raise_error(Coradoc::UnsupportedFormatError)
    end
  end

  describe '.parse' do
    it 'parses Markdown text to CoreModel' do
      doc = Coradoc.parse("# Title\n\nContent", format: :markdown)
      expect(doc).to be_a(Coradoc::CoreModel::Base)
    end

    it 'raises UnsupportedFormatError for unregistered format' do
      expect { Coradoc.parse('text', format: :nonexistent) }.to raise_error(Coradoc::UnsupportedFormatError)
    end
  end

  describe '.serialize' do
    it 'serializes CoreModel to HTML' do
      doc = Coradoc.parse("# Title\n\nParagraph", format: :markdown)
      html = Coradoc.serialize(doc, to: :html)
      expect(html).to include('<!DOCTYPE html>')
    end

    it 'raises UnsupportedFormatError for unregistered format' do
      doc = Coradoc::CoreModel::StructuralElement.new(element_type: 'document')
      expect { Coradoc.serialize(doc, to: :nonexistent) }.to raise_error(Coradoc::UnsupportedFormatError)
    end
  end

  describe '.to_core' do
    it 'returns CoreModel as-is' do
      doc = Coradoc::CoreModel::StructuralElement.new(element_type: 'document')
      expect(Coradoc.to_core(doc)).to eq(doc)
    end

    it 'transforms Markdown model via handles_model? dispatch' do
      md_doc = Coradoc::Markdown.parse("# Title\n\nContent")
      core = Coradoc.to_core(md_doc)
      expect(core).to be_a(Coradoc::CoreModel::Base)
    end

    it 'raises TransformationError for unknown model type' do
      expect { Coradoc.to_core(Object.new) }.to raise_error(Coradoc::TransformationError)
    end
  end

  describe '.detect_format (driven by registration options)' do
    it 'detects AsciiDoc from .adoc extension' do
      expect(Coradoc.detect_format('document.adoc')).to eq(:asciidoc)
    end

    it 'detects HTML from .htm extension' do
      expect(Coradoc.detect_format('page.htm')).to eq(:html)
    end

    it 'detects Markdown from .mdown extension' do
      expect(Coradoc.detect_format('doc.mdown')).to eq(:markdown)
    end

    it 'returns nil for unknown extensions' do
      expect(Coradoc.detect_format('file.txt')).to be_nil
    end
  end

  describe '.binary_format? (driven by registration options)' do
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

  describe '.normalize_format (driven by registration aliases)' do
    it 'normalizes adoc to :asciidoc' do
      expect(Coradoc.normalize_format('adoc')).to eq(:asciidoc)
    end

    it 'normalizes md to :markdown' do
      expect(Coradoc.normalize_format('md')).to eq(:markdown)
    end

    it 'passes through unknown formats as symbols' do
      expect(Coradoc.normalize_format('custom')).to eq(:custom)
    end

    it 'returns nil for nil' do
      expect(Coradoc.normalize_format(nil)).to be_nil
    end

    it 'handles symbols' do
      expect(Coradoc.normalize_format(:adoc)).to eq(:asciidoc)
    end

    it 'is case-insensitive' do
      expect(Coradoc.normalize_format('ADOC')).to eq(:asciidoc)
    end
  end

  describe '.serialize_format?' do
    it 'returns true for :html' do
      expect(Coradoc.serialize_format?(:html)).to be true
    end

    it 'returns true for :markdown' do
      expect(Coradoc.serialize_format?(:markdown)).to be true
    end

    it 'returns true for :asciidoc' do
      expect(Coradoc.serialize_format?(:asciidoc)).to be true
    end

    it 'returns true for :docx (supports serialization)' do
      expect(Coradoc.serialize_format?(:docx)).to be true
    end

    it 'returns false for unregistered format' do
      expect(Coradoc.serialize_format?(:nonexistent)).to be false
    end
  end

  describe '.parse_format?' do
    it 'returns true for :markdown' do
      expect(Coradoc.parse_format?(:markdown)).to be true
    end

    it 'returns true for :html' do
      expect(Coradoc.parse_format?(:html)).to be true
    end

    it 'returns true for :asciidoc' do
      expect(Coradoc.parse_format?(:asciidoc)).to be true
    end

    it 'returns true for :docx' do
      expect(Coradoc.parse_format?(:docx)).to be true
    end

    it 'returns false for unregistered format' do
      expect(Coradoc.parse_format?(:nonexistent)).to be false
    end
  end

  describe '.resolve_output_format' do
    it 'detects format from output filename' do
      expect(Coradoc.resolve_output_format('output.html')).to eq(:html)
    end

    it 'detects markdown from output filename' do
      expect(Coradoc.resolve_output_format('out.md')).to eq(:markdown)
    end

    it 'defaults to :html when no output file given' do
      expect(Coradoc.resolve_output_format(nil)).to eq(:html)
    end

    it 'defaults to :html for unknown extension' do
      expect(Coradoc.resolve_output_format('output.xyz')).to eq(:html)
    end
  end

  describe '.file_info' do
    let(:temp_dir) { Dir.mktmpdir('coradoc_file_info_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    it 'returns file size and format for text files' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, "# Title\n\nContent")

      info = Coradoc.file_info(file)

      expect(info[:format]).to eq(:markdown)
      expect(info[:size]).to be > 0
      expect(info[:lines]).to eq(3)
    end

    it 'omits lines for binary formats' do
      file = File.join(temp_dir, 'doc.docx')
      File.write(file, 'binary content')

      info = Coradoc.file_info(file)

      expect(info[:format]).to eq(:docx)
      expect(info).not_to have_key(:lines)
    end
  end

  describe '.validate_file' do
    let(:temp_dir) { Dir.mktmpdir('coradoc_validate_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    it 'returns a Validation::Result for a parseable document' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, "# Title\n\nContent")

      result = Coradoc.validate_file(file)

      expect(result).to be_a(Coradoc::Validation::Result)
    end

    it 'raises UnsupportedFormatError for unknown extension' do
      file = File.join(temp_dir, 'doc.xyz')
      File.write(file, 'content')

      expect { Coradoc.validate_file(file) }.to raise_error(Coradoc::UnsupportedFormatError)
    end

    it 'accepts explicit format option' do
      file = File.join(temp_dir, 'doc.txt')
      File.write(file, "# Title\n\nParagraph")

      result = Coradoc.validate_file(file, format: :markdown)

      expect(result).to be_a(Coradoc::Validation::Result)
    end
  end

  describe '.document_stats' do
    it 'returns title for documents with title' do
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'My Doc',
        children: []
      )

      stats = Coradoc.document_stats(doc)

      expect(stats[:title]).to eq('My Doc')
    end

    it 'returns child_count for documents with children' do
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'A'),
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'B')
        ]
      )

      stats = Coradoc.document_stats(doc)

      expect(stats[:child_count]).to eq(2)
    end

    it 'returns empty hash for elements without children' do
      doc = Coradoc::CoreModel::Image.new(src: 'test.png')

      stats = Coradoc.document_stats(doc)

      expect(stats).to eq({})
    end
  end

  describe '.describe_element' do
    it 'describes elements with title' do
      elem = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'My Doc'
      )

      expect(Coradoc.describe_element(elem)).to eq('StructuralElement: My Doc')
    end

    it 'describes elements with content' do
      elem = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: 'Some text here'
      )

      expect(Coradoc.describe_element(elem)).to eq('Block: Some text here')
    end

    it 'truncates long content' do
      long_text = 'A' * 60
      elem = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: long_text
      )

      expect(Coradoc.describe_element(elem)).to eq("Block: #{'A' * 51}...")
    end

    it 'describes elements without title or content' do
      elem = Coradoc::CoreModel::Image.new(src: 'test.png')

      expect(Coradoc.describe_element(elem)).to eq('Image')
    end

    it 'returns to_s for non-CoreModel objects' do
      expect(Coradoc.describe_element('plain string')).to eq('plain string')
    end
  end

  describe '.strip_unicode' do
    it 'strips unicode whitespace from both ends' do
      expect(Coradoc.strip_unicode("\u00A0hello\u00A0")).to eq('hello')
    end

    it 'strips only from beginning when only: :begin' do
      expect(Coradoc.strip_unicode("\u00A0hello\u00A0", only: :begin)).to eq("hello\u00A0")
    end

    it 'strips only from end when only: :end' do
      expect(Coradoc.strip_unicode("\u00A0hello\u00A0", only: :end)).to eq("\u00A0hello")
    end

    it 'returns nil for nil input' do
      expect(Coradoc.strip_unicode(nil)).to be_nil
    end

    it 'strips regular spaces too (\\p{Zs} includes ASCII space)' do
      expect(Coradoc.strip_unicode(' hello ')).to eq('hello')
    end

    it 'preserves internal whitespace' do
      expect(Coradoc.strip_unicode("\u00A0hello world\u00A0")).to eq('hello world')
    end
  end
end
