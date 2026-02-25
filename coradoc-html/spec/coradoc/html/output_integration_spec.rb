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

    it 'supports different CSS themes' do
      html_professional = Coradoc::Html::Static.convert(document, css_theme: :professional)
      html_academic = Coradoc::Html::Static.convert(document, css_theme: :academic)
      html_tech = Coradoc::Html::Static.convert(document, css_theme: :tech)

      expect(html_professional).to include('<!DOCTYPE html>')
      expect(html_academic).to include('<!DOCTYPE html>')
      expect(html_tech).to include('<!DOCTYPE html>')
    end
  end

  describe 'Coradoc::Html::Spa' do
    it 'converts a real AsciiDoc document to SPA HTML' do
      html = Coradoc::Html::Spa.convert(document)

      # Basic structure
      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('<html')
      expect(html).to include('</html>')

      # Vue.js presence
      expect(html).to include('unpkg.com/vue')
      expect(html).to include('Vue')

      # Tailwind CSS presence
      expect(html).to include('cdn.tailwindcss.com')
      expect(html).to include('tailwind')

      # Document data embedded in Vue app
      expect(html).to include('createApp')
    end

    it 'includes theme toggle when configured' do
      html = Coradoc::Html::Spa.convert(document, theme_toggle: true)

      expect(html).to include('isDark')
    end

    it 'includes reading progress when configured' do
      html = Coradoc::Html::Spa.convert(document, reading_progress: true)

      expect(html).to include('scrollProgress')
    end

    it 'supports different theme variants' do
      html_glass = Coradoc::Html::Spa.convert(document, theme_variant: :glass)
      html_minimal = Coradoc::Html::Spa.convert(document, theme_variant: :minimal)
      html_vibrant = Coradoc::Html::Spa.convert(document, theme_variant: :vibrant)

      expect(html_glass).to include('<!DOCTYPE html>')
      expect(html_minimal).to include('<!DOCTYPE html>')
      expect(html_vibrant).to include('<!DOCTYPE html>')
    end

    it 'supports custom colors' do
      html = Coradoc::Html::Spa.convert(document,
                                        primary_color: '#ff0000',
                                        accent_color: '#00ff00')

      expect(html).to include('#ff0000')
      expect(html).to include('#00ff00')
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
        expect(html).to include('Vue')
      end
    end

    describe '.serialize_as' do
      it 'converts to static format' do
        html = Coradoc::Html.serialize_as(document, :static)
        expect(html).to include('<!DOCTYPE html>')
      end

      it 'converts to spa format' do
        html = Coradoc::Html.serialize_as(document, :spa)
        expect(html).to include('Vue')
      end

      it 'accepts html_static alias' do
        html = Coradoc::Html.serialize_as(document, :html_static)
        expect(html).to include('<!DOCTYPE html>')
      end

      it 'accepts html_spa alias' do
        html = Coradoc::Html.serialize_as(document, :html_spa)
        expect(html).to include('Vue')
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
        expect(result['test.html']).to include('Vue')
      end
    end

    describe 'Coradoc::Output::Spa alias' do
      it 'is an alias for HtmlSpa' do
        expect(Coradoc::Output::Spa).to eq(Coradoc::Output::HtmlSpa)
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
        expect(content).to include('Vue')
        expect(content).to include('Sample Document')
      end
    end
  end
end
