# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# AsciiDoc's `= Title` document header must be visible to renderers that
# walk the body's children. Asciidoctor itself renders the title as an
# <h1> at the top of the body by default. Before this fix, the title
# lived only on DocumentElement#title — body-walking consumers (the
# standard ProseMirror/HTML pattern) never saw it and emitted pages
# with no top-level heading.
#
# The fix emits a level-0 HeaderElement as the first body child (after
# any FrontmatterBlock). HeaderElement at level 0 has document-title
# semantics per StructuralElement: section numbering and TOC builders
# skip it so the title is not counted as "section 1". FromCoreModel
# consumes the HeaderElement when building Model::Header so AsciiDoc
# round-trip does not double-render the title.
RSpec.describe 'Document title emitted as body HeaderElement', :asciidoc do
  def parse(adoc)
    Coradoc.parse(adoc, format: :asciidoc)
  end

  describe 'simple document with title' do
    let(:adoc) { "= Hello World\n\nBody.\n" }
    let(:doc) { parse(adoc) }

    it 'preserves title on DocumentElement#title' do
      expect(doc.title).to eq('Hello World')
    end

    it 'emits HeaderElement as first body child' do
      expect(doc.children.first).to be_a(Coradoc::CoreModel::HeaderElement)
    end

    it 'sets HeaderElement level to 0' do
      expect(doc.children.first.level).to eq(0)
    end

    it 'sets HeaderElement title to the document title' do
      expect(doc.children.first.title).to eq('Hello World')
    end

    it 'reports the HeaderElement as a document title' do
      expect(doc.children.first.document_title?).to be(true)
    end
  end

  describe 'document with no title' do
    let(:adoc) { "Just a body paragraph.\n" }
    let(:doc) { parse(adoc) }

    it 'does not synthesise a HeaderElement' do
      has_header = doc.children.any? do |c|
        c.is_a?(Coradoc::CoreModel::HeaderElement)
      end
      expect(has_header).to be(false)
    end
  end

  describe 'document with frontmatter' do
    let(:adoc) { "---\ntitle: Frontmatter Title\n---\n= Real Title\n\nBody.\n" }

    it 'places HeaderElement after the FrontmatterBlock' do
      doc = parse(adoc)
      frontmatter_idx = doc.children.index do |c|
        c.is_a?(Coradoc::CoreModel::FrontmatterBlock)
      end
      header_idx = doc.children.index do |c|
        c.is_a?(Coradoc::CoreModel::HeaderElement)
      end
      expect(frontmatter_idx).not_to be_nil
      expect(header_idx).not_to be_nil
      expect(header_idx).to be > frontmatter_idx
    end
  end

  describe 'AsciiDoc round-trip' do
    let(:adoc) { "= Hello World\n\nBody.\n" }

    it 'round-trips without double-rendering the title' do
      core = parse(adoc)
      model = Coradoc::AsciiDoc::Transform::FromCoreModel.transform(core)
      # Model::Document carries the title via Model::Header (from
      # extract_title_heading). No child Section should carry the same
      # title — that would be the double-render regression.
      section_titles = Array(model.sections).map { |s| s.title&.content.to_s }
      expect(section_titles).not_to include('Hello World')
      expect(model.header.title.content).to include('Hello World')
    end
  end
end
