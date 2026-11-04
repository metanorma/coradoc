# frozen_string_literal: true

require 'coradoc/markdown'
require_relative '../spec_helper'

# Footnotes bridge: the uniword-critical shape (DocumentRoot with a
# Footnotes part and a w:footnoteReference run inside a body paragraph)
# must reach Markdown with both the reference and the definition.
RSpec.describe 'DOCX footnotes to Markdown bridge', type: :integration do
  def build_footnoted_document
    doc = Uniword::Builder::DocumentBuilder.new
    doc.title('Footnote Probe')
    doc.paragraph do |p|
      p << 'Body with note '
      p << doc.footnote('the note body')
      p << ' end.'
    end
    doc.paragraph('After.')
    doc.build
  end

  it 'carries the footnote definition into the core model' do
    core = Coradoc::Docx.parse_to_core(build_footnoted_document)

    defs = core.children.grep(Coradoc::CoreModel::Footnote)
    expect(defs.map(&:id)).to eq(%w[1])
    expect(defs.first.content).to eq('the note body')
  end

  it 'emits both the reference and the definition in Markdown' do
    md = Coradoc::Markdown.serialize(Coradoc::Docx.parse_to_core(build_footnoted_document))

    expect(md).to include('Body with note [^1] end.')
    expect(md).to include('[^1]: the note body')
    expect(md.index('[^1]')).to be < md.index('[^1]: the note body')
  end

  it 'round-trips the Markdown back to a footnotes part' do
    md = Coradoc::Markdown.serialize(Coradoc::Docx.parse_to_core(build_footnoted_document))

    core = Coradoc::Markdown.parse_to_core(md)
    root = Coradoc::Docx::Transform::FromCoreModel.transform(core)

    entries = root.footnotes.footnote_entries
    expect(entries.map(&:id)).to eq(%w[1])
    expect(run_text(entries.first.paragraphs.first.runs.first)).to eq('the note body')
  end
end
