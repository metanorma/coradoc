# frozen_string_literal: true

require 'tmpdir'
require_relative '../spec_helper'

RSpec.describe 'DOCX round-trip', type: :integration do
  describe 'FromCoreModel' do
    it 'preserves document title and paragraph text' do
      doc = build_document
      doc.body.paragraphs << build_heading('My Title', level: 1)
      doc.body.paragraphs << build_paragraph('Hello world')

      core = transform_to_core(doc)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
      # Heading becomes the document's core_properties.title, not a body paragraph
      expect(result.title).to eq('My Title')
      # Body paragraph is preserved
      paragraphs = result.body.paragraphs
      expect(paragraphs.size).to be >= 1
      expect(paragraphs[0].runs.first.text.content).to eq('Hello world')
    end

    it 'preserves table cell content' do
      doc = build_document
      doc.body.paragraphs << build_heading('Title', level: 1)
      doc.body.tables << build_table([%w[A B], %w[C D]])

      core = transform_to_core(doc)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
      tables = result.body.tables
      expect(tables.size).to be >= 1
      rows = tables.first.rows
      expect(rows.size).to eq(2)
      expect(rows[0].cells.map { |c| c.paragraphs.first.runs.first.text.content }).to eq(%w[A B])
      expect(rows[1].cells.map { |c| c.paragraphs.first.runs.first.text.content }).to eq(%w[C D])
    end

    it 'preserves bold and italic runs' do
      doc = build_document
      doc.body.paragraphs << build_paragraph(
        'Normal ',
        build_run('bold', bold: true),
        ' and ',
        build_run('italic', italic: true)
      )

      core = transform_to_core(doc)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
      para = result.body.paragraphs.first
      runs = para.runs
      expect(runs.map { |r| r.text.content }).to include('bold', 'italic')

      bold_run = runs.find { |r| r.text.content == 'bold' }
      italic_run = runs.find { |r| r.text.content == 'italic' }
      expect(bold_run.properties).not_to be_nil
      expect(bold_run.properties.bold).not_to be_nil
      expect(italic_run.properties).not_to be_nil
      expect(italic_run.properties.italic).not_to be_nil
    end

    it 'preserves list item content' do
      doc = build_document
      doc.body.paragraphs << build_list_paragraph('Item 1', num_id: 1)
      doc.body.paragraphs << build_list_paragraph('Item 2', num_id: 1)

      core = transform_to_core(doc)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
      paragraphs = result.body.paragraphs
      item_texts = paragraphs.select { |p| p.properties&.num_id }.map { |p| p.runs.first.text.content }
      expect(item_texts).to contain_exactly('Item 1', 'Item 2')
    end
  end

  describe 'serialize' do
    it 'returns a DocumentRoot when no output_path given' do
      doc = build_document
      doc.body.paragraphs << build_heading('Title', level: 1)
      doc.body.paragraphs << build_paragraph('Content')

      core = transform_to_core(doc)
      result = Coradoc::Docx.serialize(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'writes a .docx file when output_path given' do
      doc = build_document
      doc.body.paragraphs << build_heading('Title', level: 1)
      doc.body.paragraphs << build_paragraph('Content to serialize')

      core = transform_to_core(doc)

      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.docx')
        result = Coradoc::Docx.serialize(core, output_path: path)

        expect(result).to eq(path)
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0 # rubocop:disable Style/NumericPredicate
      end
    end

    it 'serialize? returns true' do
      expect(Coradoc::Docx.serialize?).to be true
    end
  end
end
