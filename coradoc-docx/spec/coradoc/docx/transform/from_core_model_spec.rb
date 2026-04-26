# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../../../spec_helper'

RSpec.describe Coradoc::Docx::Transform::FromCoreModel do
  describe '.transform' do
    subject(:result) { described_class.transform(core_model) }

    context 'with FootnoteReference' do
      let(:core_model) { Coradoc::CoreModel::FootnoteReference.new(id: '42') }

      it 'produces a Run with footnote reference' do
        expect(result).to be_a(Uniword::Wordprocessingml::Run)
        expect(result.footnote_reference).to be_a(Uniword::Wordprocessingml::FootnoteReference)
        expect(result.footnote_reference.id).to eq('42')
      end
    end

    context 'with Footnote' do
      let(:core_model) { Coradoc::CoreModel::Footnote.new(id: '1', content: 'Footnote text') }

      it 'produces a Paragraph with footnote content' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        expect(result.runs.first.text.content).to eq('Footnote text')
      end
    end

    context 'with DefinitionList' do
      let(:core_model) do
        Coradoc::CoreModel::DefinitionList.new(
          items: [
            Coradoc::CoreModel::DefinitionItem.new(
              term: 'Term 1',
              definitions: ['Definition of term 1']
            )
          ]
        )
      end

      it 'produces a Table with term and definition columns' do
        expect(result).to be_a(Uniword::Wordprocessingml::Table)
        expect(result.rows.length).to eq(1)
        expect(result.rows[0].cells.length).to eq(2)
        term_text = result.rows[0].cells[0].paragraphs.first.runs.first.text.content
        def_text = result.rows[0].cells[1].paragraphs.first.runs.first.text.content
        expect(term_text).to eq('Term 1')
        expect(def_text).to eq('Definition of term 1')
      end

      it 'bolds the term cell' do
        term_run = result.rows[0].cells[0].paragraphs.first.runs.first
        expect(term_run.properties).not_to be_nil
        expect(term_run.properties.bold).not_to be_nil
      end
    end

    context 'with Toc' do
      let(:core_model) { Coradoc::CoreModel::Toc.new }

      it 'produces a Paragraph placeholder' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        expect(result.runs.first.text.content).to eq('[Table of Contents]')
      end
    end

    context 'with Term' do
      let(:core_model) { Coradoc::CoreModel::Term.new(text: 'Ruby', type: 'noun') }

      it 'produces a bold Paragraph' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        expect(result.runs.first.text.content).to eq('Ruby')
        expect(result.runs.first.properties).not_to be_nil
        expect(result.runs.first.properties.bold).not_to be_nil
      end
    end

    context 'with InlineElement highlight' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(format_type: 'highlight', content: 'highlighted')
      end

      it 'produces a Run with highlight property' do
        expect(result).to be_a(Uniword::Wordprocessingml::Run)
        expect(result.properties).not_to be_nil
        expect(result.properties.highlight).not_to be_nil
      end
    end

    context 'with InlineElement xref' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(format_type: 'xref', content: 'See here', target: 'section1')
      end

      it 'produces a Run with content' do
        expect(result).to be_a(Uniword::Wordprocessingml::Run)
      end
    end

    context 'with document containing mixed types' do
      let(:core_model) do
        Coradoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          title: 'Test Doc',
          children: [
            Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'First para'),
            Coradoc::CoreModel::DefinitionList.new(
              items: [
                Coradoc::CoreModel::DefinitionItem.new(term: 'Foo', definitions: ['Bar'])
              ]
            )
          ]
        )
      end

      it 'produces a DocumentRoot with all children' do
        expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
      end
    end

    context 'with Abbreviation' do
      let(:core_model) { Coradoc::CoreModel::Abbreviation.new(term: 'API', definition: 'Application Programming Interface') }

      it 'produces a Paragraph with term and definition' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        expect(result.runs.first.text.content).to eq('API (Application Programming Interface)')
      end
    end

    context 'with Bibliography' do
      let(:core_model) do
        Coradoc::CoreModel::Bibliography.new(
          title: 'References',
          entries: [
            Coradoc::CoreModel::BibliographyEntry.new(document_id: 'ISO 712', ref_text: 'Cereals.')
          ]
        )
      end

      it 'produces an array with heading and entries' do
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        # First element is the heading paragraph
        heading = result[0]
        expect(heading).to be_a(Uniword::Wordprocessingml::Paragraph)
        expect(heading.properties.style.value).to eq('Heading2')
        # Second element is the entry paragraph
        entry_para = result[1]
        expect(entry_para).to be_a(Uniword::Wordprocessingml::Paragraph)
        expect(entry_para.runs.first.text.content).to eq('ISO 712: Cereals.')
      end
    end

    context 'with BibliographyEntry' do
      let(:core_model) do
        Coradoc::CoreModel::BibliographyEntry.new(document_id: 'ISO 712', ref_text: 'Cereals.')
      end

      it 'produces a Paragraph with formatted entry text' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        expect(result.runs.first.text.content).to eq('ISO 712: Cereals.')
      end
    end

    context 'with TocEntry' do
      let(:core_model) { Coradoc::CoreModel::TocEntry.new(title: 'Section 1', level: 1) }

      it 'produces a Paragraph with title' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        expect(result.runs.first.text.content).to eq('Section 1')
      end
    end

    context 'with Block (paragraph)' do
      let(:core_model) { Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Hello world') }

      it 'produces a Paragraph with text content' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        expect(result.runs.first.text.content).to eq('Hello world')
      end
    end

    context 'with Block (page_break)' do
      let(:core_model) { Coradoc::CoreModel::Block.new(element_type: 'page_break') }

      it 'produces a Paragraph with page break' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        expect(result.runs.first.break).not_to be_nil
        expect(result.runs.first.break.type).to eq('page')
      end
    end

    context 'with ListBlock' do
      let(:core_model) do
        Coradoc::CoreModel::ListBlock.new(
          marker_type: 'ordered',
          items: [
            Coradoc::CoreModel::ListItem.new(text: 'First'),
            Coradoc::CoreModel::ListItem.new(text: 'Second')
          ]
        )
      end

      it 'produces an array of Paragraphs' do
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result).to all(be_a(Uniword::Wordprocessingml::Paragraph))
      end
    end

    context 'with Table' do
      let(:core_model) do
        Coradoc::CoreModel::Table.new(
          rows: [
            Coradoc::CoreModel::TableRow.new(
              cells: [
                Coradoc::CoreModel::TableCell.new(content: 'A'),
                Coradoc::CoreModel::TableCell.new(content: 'B')
              ]
            )
          ]
        )
      end

      it 'produces an OOXML Table' do
        expect(result).to be_a(Uniword::Wordprocessingml::Table)
        expect(result.rows.length).to eq(1)
      end
    end

    context 'with Image (missing file)' do
      let(:core_model) { Coradoc::CoreModel::Image.new(src: 'nonexistent.png', alt: 'Test') }

      it 'produces a Paragraph with text placeholder' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        text = result.runs.first.text.content
        expect(text).to eq('[Image: Test]')
      end
    end

    context 'with Image (real file)' do
      let(:core_model) do
        require 'tmpdir'
        @tmpdir = Dir.mktmpdir
        img_path = File.join(@tmpdir, 'test.png')
        # Minimal 1x1 PNG
        File.binwrite(img_path, "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xAEB`\x82".b)
        Coradoc::CoreModel::Image.new(src: img_path, alt: 'Test image')
      end

      after do
        FileUtils.remove_entry(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
      end

      it 'produces a Paragraph with a Drawing element' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        run = result.runs.first
        expect(run.drawings).not_to be_empty
      end
    end

    context 'with AnnotationBlock' do
      let(:core_model) { Coradoc::CoreModel::AnnotationBlock.new(annotation_type: 'NOTE', content: 'Be careful') }

      it 'produces a Paragraph with annotation type prefix and content' do
        expect(result).to be_a(Uniword::Wordprocessingml::Paragraph)
        runs = result.runs
        # First run: bold "NOTE: " prefix
        expect(runs[0].text.content).to eq('NOTE: ')
        expect(runs[0].properties.bold).not_to be_nil
        # Second run: content text
        expect(runs[1].text.content).to eq('Be careful')
      end
    end

    context 'with InlineElement bold' do
      let(:core_model) { Coradoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'bold text') }

      it 'produces a Run with bold property' do
        expect(result).to be_a(Uniword::Wordprocessingml::Run)
        expect(result.properties).not_to be_nil
        expect(result.properties.bold).not_to be_nil
      end
    end

    context 'with InlineElement italic' do
      let(:core_model) { Coradoc::CoreModel::InlineElement.new(format_type: 'italic', content: 'italic text') }

      it 'produces a Run with italic property' do
        expect(result).to be_a(Uniword::Wordprocessingml::Run)
        expect(result.properties.italic).not_to be_nil
      end
    end

    context 'with InlineElement underline' do
      let(:core_model) { Coradoc::CoreModel::InlineElement.new(format_type: 'underline', content: 'underlined') }

      it 'produces a Run with underline property' do
        expect(result).to be_a(Uniword::Wordprocessingml::Run)
        expect(result.properties.underline).not_to be_nil
      end
    end
  end
end
