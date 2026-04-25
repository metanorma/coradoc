# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../spec_helper'

RSpec.describe 'DOCX real-file integration', type: :integration do
  # Helper: create a minimal 1x1 PNG file
  let(:minimal_png) do
    png = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xAEB`\x82".b
    path = File.join(@tmpdir, 'fixture.png')
    File.binwrite(path, png)
    path
  end

  before do
    @tmpdir = Dir.mktmpdir
  end

  after do
    FileUtils.remove_entry(@tmpdir)
  end

  describe 'Uniword Builder fixture generation + round-trip' do
    it 'round-trips a document with headings and paragraphs' do
      doc = Uniword::Builder::DocumentBuilder.new
      doc.heading('Test Document', level: 1)
      doc.paragraph('First paragraph of content.')
      doc.heading('Section One', level: 2)
      doc.paragraph('Content under section one.')

      # Write to DOCX
      docx_path = File.join(@tmpdir, 'heading_test.docx')
      doc.build.save(docx_path)
      expect(File.exist?(docx_path)).to be true

      # Parse back through ToCoreModel
      loaded = Uniword.load(docx_path)
      core = Coradoc::Docx.parse_to_core(loaded)
      expect(core).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(core.element_type).to eq('document')

      # Round-trip back through FromCoreModel
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)
      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'round-trips a document with a table' do
      doc = Uniword::Builder::DocumentBuilder.new
      doc.heading('Table Test', level: 1)
      doc.table do |t|
        t.row do |r|
          r.cell(text: 'Header A')
          r.cell(text: 'Header B')
        end
        t.row do |r|
          r.cell(text: 'Data 1')
          r.cell(text: 'Data 2')
        end
      end

      docx_path = File.join(@tmpdir, 'table_test.docx')
      doc.build.save(docx_path)

      loaded = Uniword.load(docx_path)
      core = Coradoc::Docx.parse_to_core(loaded)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'round-trips a document with inline formatting' do
      doc = Uniword::Builder::DocumentBuilder.new
      doc.heading('Formatting Test', level: 1)
      doc.paragraph do |p|
        p << 'Normal text, '
        p << Uniword::Builder.text('bold text', bold: true)
        p << ', and '
        p << Uniword::Builder.text('italic text', italic: true)
      end

      docx_path = File.join(@tmpdir, 'format_test.docx')
      doc.build.save(docx_path)

      loaded = Uniword.load(docx_path)
      core = Coradoc::Docx.parse_to_core(loaded)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'round-trips a document with a list' do
      doc = Uniword::Builder::DocumentBuilder.new
      doc.heading('List Test', level: 1)
      doc.bullet_list do |l|
        l.item('First bullet')
        l.item('Second bullet')
        l.item('Third bullet')
      end

      docx_path = File.join(@tmpdir, 'list_test.docx')
      doc.build.save(docx_path)

      loaded = Uniword.load(docx_path)
      core = Coradoc::Docx.parse_to_core(loaded)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'round-trips a document with an embedded image' do
      doc = Uniword::Builder::DocumentBuilder.new
      doc.heading('Image Test', level: 1)
      doc.image(minimal_png, alt_text: 'Test image')
      doc.paragraph('Text after image.')

      docx_path = File.join(@tmpdir, 'image_test.docx')
      doc.build.save(docx_path)
      expect(File.size(docx_path)).to be > 0

      loaded = Uniword.load(docx_path)
      core = Coradoc::Docx.parse_to_core(loaded)
      expect(core).to be_a(Coradoc::CoreModel::StructuralElement)

      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)
      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'round-trips a document with a page break' do
      doc = Uniword::Builder::DocumentBuilder.new
      doc.heading('Page One', level: 1)
      doc.paragraph('Content on page one.')
      doc.page_break
      doc.heading('Page Two', level: 1)
      doc.paragraph('Content on page two.')

      docx_path = File.join(@tmpdir, 'pagebreak_test.docx')
      doc.build.save(docx_path)

      loaded = Uniword.load(docx_path)
      core = Coradoc::Docx.parse_to_core(loaded)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'round-trips a complex document with mixed elements' do
      doc = Uniword::Builder::DocumentBuilder.new
      doc.heading('Complex Document', level: 1)
      doc.paragraph('Introduction paragraph.')

      doc.heading('Data Section', level: 2)
      doc.paragraph do |p|
        p << 'This has '
        p << Uniword::Builder.text('bold', bold: true)
        p << ' and '
        p << Uniword::Builder.text('italic', italic: true)
        p << ' text.'
      end

      doc.table do |t|
        t.row do |r|
          r.cell(text: 'A')
          r.cell(text: 'B')
        end
        t.row do |r|
          r.cell(text: 'C')
          r.cell(text: 'D')
        end
      end

      doc.bullet_list do |l|
        l.item('Point one')
        l.item('Point two')
      end

      doc.paragraph('Final paragraph.')

      docx_path = File.join(@tmpdir, 'complex_test.docx')
      doc.build.save(docx_path)

      loaded = Uniword.load(docx_path)
      core = Coradoc::Docx.parse_to_core(loaded)
      result = Coradoc::Docx::Transform::FromCoreModel.transform(core)

      expect(result).to be_a(Uniword::Wordprocessingml::DocumentRoot)

      # Serialize back to a new file to verify full pipeline
      output_path = File.join(@tmpdir, 'complex_output.docx')
      result.save(output_path)
      expect(File.exist?(output_path)).to be true
      expect(File.size(output_path)).to be > 0
    end
  end

  describe 'serialize with real file output' do
    it 'writes a valid DOCX from a CoreModel built by hand' do
      core = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Serialized Document',
        children: [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Paragraph one.'),
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Paragraph two.'),
          Coradoc::CoreModel::ListBlock.new(
            marker_type: 'ordered',
            items: [
              Coradoc::CoreModel::ListItem.new(text: 'Item A'),
              Coradoc::CoreModel::ListItem.new(text: 'Item B')
            ]
          )
        ]
      )

      output_path = File.join(@tmpdir, 'serialized.docx')
      result = Coradoc::Docx.serialize(core, output_path: output_path)

      expect(result).to eq(output_path)
      expect(File.exist?(output_path)).to be true
      expect(File.size(output_path)).to be > 0

      # Verify the written file is parseable
      loaded = Uniword.load(output_path)
      expect(loaded).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end

    it 'writes a DOCX with image from CoreModel' do
      core = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Image Document',
        children: [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Before image.'),
          Coradoc::CoreModel::Image.new(src: minimal_png, alt: 'Embedded image'),
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'After image.')
        ]
      )

      output_path = File.join(@tmpdir, 'with_image.docx')
      result = Coradoc::Docx.serialize(core, output_path: output_path)

      expect(result).to eq(output_path)
      expect(File.exist?(output_path)).to be true
      expect(File.size(output_path)).to be > 0

      # Verify the written file is parseable
      loaded = Uniword.load(output_path)
      expect(loaded).to be_a(Uniword::Wordprocessingml::DocumentRoot)
    end
  end
end
