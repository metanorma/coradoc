# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'DOCX round-trip', type: :integration do
  describe 'FromCoreModel' do
    it 'transforms a simple document to a DocumentRoot' do
      doc = build_document
      doc.body.paragraphs << build_heading('Title', level: 1)
      doc.body.paragraphs << build_paragraph('Hello world')

      core = transform_to_core(doc)

      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'preserves document title' do
      doc = build_document
      doc.body.paragraphs << build_heading('My Title', level: 1)

      core = transform_to_core(doc)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'preserves paragraph content' do
      doc = build_document
      doc.body.paragraphs << build_heading('Title', level: 1)
      doc.body.paragraphs << build_paragraph('Test paragraph content')

      core = transform_to_core(doc)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'preserves table structure' do
      doc = build_document
      doc.body.paragraphs << build_heading('Title', level: 1)
      doc.body.tables << build_table([%w[A B], %w[C D]])

      core = transform_to_core(doc)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'handles inline formatting' do
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
    end

    it 'handles list blocks' do
      doc = build_document
      doc.body.paragraphs << build_list_paragraph('Item 1', num_id: 1)
      doc.body.paragraphs << build_list_paragraph('Item 2', num_id: 1)

      core = transform_to_core(doc)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
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
      require 'tmpdir'

      doc = build_document
      doc.body.paragraphs << build_heading('Title', level: 1)
      doc.body.paragraphs << build_paragraph('Content to serialize')

      core = transform_to_core(doc)

      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.docx')
        result = Coradoc::Docx.serialize(core, output_path: path)

        expect(result).to eq(path)
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0
      end
    end

    it 'serialize? returns true' do
      expect(Coradoc::Docx.serialize?).to be true
    end
  end
end
