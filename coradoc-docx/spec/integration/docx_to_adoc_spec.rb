# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'DOCX to AsciiDoc conversion', type: :integration do
  it 'converts headings to AsciiDoc sections' do
    doc = build_document
    doc.body.paragraphs << build_heading('Title', level: 1)
    doc.body.paragraphs << build_heading('Section', level: 2)

    adoc = transform_to_adoc(doc)

    expect(adoc).to include('= Title')
    expect(adoc).to include('=== Section')
  end

  it 'converts paragraphs with inline formatting' do
    doc = build_document
    doc.body.paragraphs << build_paragraph(
      'Normal ',
      build_run('bold', bold: true),
      ' and ',
      build_run('italic', italic: true)
    )

    adoc = transform_to_adoc(doc)

    expect(adoc).to include('Normal **bold** and __italic__')
  end

  it 'converts tables to AsciiDoc table format' do
    doc = build_document
    doc.body.tables << build_table([
                                     %w[Header1 Header2],
                                     %w[Cell1 Cell2]
                                   ])

    adoc = transform_to_adoc(doc)

    expect(adoc).to include('|===')
    expect(adoc).to include('| Header1')
    expect(adoc).to include('| Cell1')
  end

  it 'converts bold text to *bold*' do
    doc = build_document
    doc.body.paragraphs << build_paragraph(build_run('bold', bold: true))

    adoc = transform_to_adoc(doc)

    expect(adoc).to include('*bold*')
  end

  it 'converts italic text to _italic_' do
    doc = build_document
    doc.body.paragraphs << build_paragraph(build_run('emphasized', italic: true))

    adoc = transform_to_adoc(doc)

    expect(adoc).to include('_emphasized_')
  end

  it 'handles empty document' do
    doc = build_document
    adoc = transform_to_adoc(doc)

    expect(adoc).not_to be_nil
    expect(adoc).not_to include('#<')
  end

  it 'produces no Ruby object dumps' do
    doc = build_document
    doc.body.paragraphs << build_heading('Test', level: 1)
    doc.body.paragraphs << build_paragraph('Content')
    doc.body.tables << build_table([%w[A B]])

    adoc = transform_to_adoc(doc)

    expect(adoc).not_to match(/#<.*:\h{16}/)
  end
end
