# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe 'HTML Output Integration' do
  let(:sample_adoc) do
    <<~ADOC
      = Sample Document
      :toc:
      :sectnums:

      == Introduction

      This is a sample document for testing HTML output.

      === Background

      Some background information here.

      * First item
      * Second item
      * Third item

      == Main Content

      This section contains the main content.

      [source,ruby]
      ----
      def hello_world
        puts "Hello, World!"
      end
      ----

      === Subsection

      More content in a subsection.

      NOTE: This is an important note.

      TIP: Here's a helpful tip.

      == Tables

      .Sample Table
      |===
      | Header 1 | Header 2 | Header 3

      | Cell 1
      | Cell 2
      | Cell 3

      | Cell 4
      | Cell 5
      | Cell 6
      |===

      == Conclusion

      This concludes the sample document.
    ADOC
  end

  let(:document) { Coradoc.parse(sample_adoc, format: :asciidoc) }

  describe 'Coradoc::Html::Static' do
    it 'converts a real AsciiDoc document to static HTML' do
      html = Coradoc::Html::Static.convert(document)

      # Basic structure
      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('<html')
      expect(html).to include('</html>')

      # Content
      expect(html).to include('Sample Document')
      expect(html).to include('Introduction')
      expect(html).to include('Main Content')

      # List items
      expect(html).to include('<li>')
      expect(html).to include('First item')

      # Table
      expect(html).to include('<table')
      expect(html).to include('Header 1')

      # Code block - check for code-related content
      expect(html).to include('hello_world')
    end

    it 'includes TOC when configured' do
      html = Coradoc::Html::Static.convert(document, include_toc: true)

      expect(html).to include('Table of Contents')
      expect(html).to include('toc')
    end

    it 'supports section numbering configuration' do
      html_numbered = Coradoc::Html::Static.convert(document, section_numbering: true)
      html_unnumbered = Coradoc::Html::Static.convert(document, section_numbering: false)

      expect(html_numbered).to include('<!DOCTYPE html>')
      expect(html_unnumbered).to include('<!DOCTYPE html>')
    end
  end

  describe 'Coradoc::Html::Spa' do
    it 'converts a real AsciiDoc document to SPA HTML' do
      html = Coradoc::Html::Spa.convert(document)

      # Basic structure
      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('<html')
      expect(html).to include('</html>')

      # Frontend dist assets embedded
      expect(html).to include('coradoc-app')
      expect(html).to include('CORADOC_DATA')

      # Document data embedded in Vue app
      expect(html).to include('Sample Document')
    end

    it 'includes embedded CSS from frontend dist' do
      html = Coradoc::Html::Spa.convert(document)

      expect(html).to include('<style>')
    end

    it 'includes embedded JS from frontend dist' do
      html = Coradoc::Html::Spa.convert(document)

      expect(html).to include('<script>')
    end

    it 'passes theme_toggle to renderer' do
      html = Coradoc::Html::Spa.convert(document, theme_toggle: false)

      expect(html).to include('<!DOCTYPE html>')
    end
  end

  describe 'Coradoc::Html module methods' do
    describe '.serialize_static' do
      it 'converts using Static converter' do
        html = Coradoc::Html.serialize_static(document)

        expect(html).to include('<!DOCTYPE html>')
        expect(html).to include('Sample Document')
      end
    end

    describe '.serialize_spa' do
      it 'converts using Spa converter' do
        html = Coradoc::Html.serialize_spa(document)

        expect(html).to include('<!DOCTYPE html>')
        expect(html).to include('CORADOC_DATA')
      end
    end

    describe '.serialize_as' do
      it 'converts to static format' do
        html = Coradoc::Html.serialize_as(document, :static)
        expect(html).to include('<!DOCTYPE html>')
      end

      it 'converts to spa format' do
        html = Coradoc::Html.serialize_as(document, :spa)
        expect(html).to include('CORADOC_DATA')
      end

      it 'accepts html_static alias' do
        html = Coradoc::Html.serialize_as(document, :html_static)
        expect(html).to include('<!DOCTYPE html>')
      end

      it 'accepts html_spa alias' do
        html = Coradoc::Html.serialize_as(document, :html_spa)
        expect(html).to include('CORADOC_DATA')
      end

      it 'raises error for unknown format' do
        expect do
          Coradoc::Html.serialize_as(document, :unknown)
        end.to raise_error(ArgumentError, /Unknown output format/)
      end
    end
  end

  # Output processor interface for Core::Output registration
  # Coradoc::Output::HtmlStatic and Coradoc::Output::HtmlSpa
  # are registered with the core gem's Output module
  describe 'Output processors' do
    describe 'Coradoc::Output::HtmlStatic' do
      it 'has correct processor_id' do
        expect(Coradoc::Output::HtmlStatic.processor_id).to eq(:html_static)
      end

      it 'matches HTML files' do
        expect(Coradoc::Output::HtmlStatic.processor_match?('test.html')).to be true
        expect(Coradoc::Output::HtmlStatic.processor_match?('test.htm')).to be true
        expect(Coradoc::Output::HtmlStatic.processor_match?('test.txt')).to be false
      end

      it 'processes documents' do
        input = { 'test.html' => document }
        result = Coradoc::Output::HtmlStatic.processor_execute(input, {})

        expect(result).to have_key('test.html')
        expect(result['test.html']).to include('<!DOCTYPE html>')
      end
    end

    describe 'Coradoc::Output::HtmlSpa' do
      it 'has correct processor_id' do
        expect(Coradoc::Output::HtmlSpa.processor_id).to eq(:html_spa)
      end

      it 'matches HTML files' do
        expect(Coradoc::Output::HtmlSpa.processor_match?('test.html')).to be true
        expect(Coradoc::Output::HtmlSpa.processor_match?('test.htm')).to be true
        expect(Coradoc::Output::HtmlSpa.processor_match?('test.txt')).to be false
      end

      it 'processes documents' do
        input = { 'test.html' => document }
        result = Coradoc::Output::HtmlSpa.processor_execute(input, {})

        expect(result).to have_key('test.html')
        expect(result['test.html']).to include('CORADOC_DATA')
      end
    end

    describe 'Coradoc::Output::Spa alias' do
      it 'is an alias for HtmlSpa' do
        expect(Coradoc::Output::Spa).to eq(Coradoc::Output::HtmlSpa)
      end
    end
  end

  describe 'Section numbering in HTML output' do
    let(:numbered_adoc) do
      <<~ADOC
        = Numbered Document
        :toc:
        :sectnums:

        == Introduction

        Intro text.

        === Background

        Background text.

        == Main Content

        Main text.

        === Subsection

        Subsection text.

        == Conclusion

        Conclusion text.
      ADOC
    end

    let(:numbered_doc) { Coradoc.parse(numbered_adoc, format: :asciidoc) }

    it 'renders section numbers in TOC entries' do
      html = Coradoc::Html.serialize(numbered_doc, toc: true, sectnums: true, layout: :spa)

      # Extract CORADOC_DATA JSON from the script tag
      json_match = html.match(%r{window\.CORADOC_DATA\s*=\s*(.+?);\s*</script>}m)
      data = JSON.parse(json_match[1])

      toc_entries = data['toc']['entries']
      expect(toc_entries[0]['number']).to eq('1')
      expect(toc_entries[0]['title']).to eq('Introduction')
      expect(toc_entries[0]['children'][0]['number']).to eq('1.1')
      expect(toc_entries[0]['children'][0]['title']).to eq('Background')

      expect(toc_entries[1]['number']).to eq('2')
      expect(toc_entries[1]['title']).to eq('Main Content')
      expect(toc_entries[1]['children'][0]['number']).to eq('2.1')
      expect(toc_entries[1]['children'][0]['title']).to eq('Subsection')

      expect(toc_entries[2]['number']).to eq('3')
      expect(toc_entries[2]['title']).to eq('Conclusion')
    end

    it 'renders section numbers in body headings' do
      html = Coradoc::Html.serialize(numbered_doc, toc: true, sectnums: true, layout: :spa)

      # Extract contentHtml from CORADOC_DATA
      json_match = html.match(%r{window\.CORADOC_DATA\s*=\s*(.+?);\s*</script>}m)
      data = JSON.parse(json_match[1])
      content = data['contentHtml']

      doc = Nokogiri::HTML::DocumentFragment.parse(content)
      headings = doc.css('h2, h3')
      heading_texts = headings.map(&:text)

      expect(heading_texts).to include(a_string_including('1. Introduction'))
      expect(heading_texts).to include(a_string_including('1.1. Background'))
      expect(heading_texts).to include(a_string_including('2. Main Content'))
      expect(heading_texts).to include(a_string_including('2.1. Subsection'))
      expect(heading_texts).to include(a_string_including('3. Conclusion'))
    end

    it 'omits section numbers when sectnums is not set' do
      plain_adoc = <<~ADOC
        = Plain Document
        :toc:

        == Introduction

        Intro text.

        == Conclusion

        Conclusion text.
      ADOC

      plain_doc = Coradoc.parse(plain_adoc, format: :asciidoc)
      html = Coradoc::Html.serialize(plain_doc, toc: true, layout: :spa)

      json_match = html.match(%r{window\.CORADOC_DATA\s*=\s*(.+?);\s*</script>}m)
      data = JSON.parse(json_match[1])

      entries = data['toc']['entries']
      entries.each do |entry|
        expect(entry['number']).to be_nil
      end
    end
  end

  describe 'End-to-end file output' do
    it 'writes static HTML to file' do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, 'output.html')
        Coradoc::Html::Static.to_file(document, output_path)

        expect(File.exist?(output_path)).to be true
        content = File.read(output_path)
        expect(content).to include('<!DOCTYPE html>')
        expect(content).to include('Sample Document')
      end
    end

    it 'writes SPA HTML to file' do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, 'output.html')
        Coradoc::Html::Spa.to_file(document, output_path)

        expect(File.exist?(output_path)).to be true
        content = File.read(output_path)
        expect(content).to include('<!DOCTYPE html>')
        expect(content).to include('CORADOC_DATA')
        expect(content).to include('Sample Document')
      end
    end
  end
end
