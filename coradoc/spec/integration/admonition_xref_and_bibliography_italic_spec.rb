# frozen_string_literal: true

require 'spec_helper'

# Cross-format regression for BUG-italic-inspect-and-xref-in-admonition.md.
# Two distinct bugs shared one root cause: AsciiDoc Inline model objects
# (Italic, CrossReference) were being stringified via Object#to_s, which
# leaks the Ruby `#<Class:0x...>` inspect string into the output.
#
# Bug 1: Bibliography entries containing _italic_ text produced
#   `#<Coradoc::AsciiDoc::Model::Inline::Italic:0x...>` instead of the
#   actual title text.
#
# Bug 2: `<<anchor>>` cross-references inside `NOTE:` admonitions stayed
#   literal in Markdown output (or produced inspect strings) instead of
#   becoming `[anchor](#anchor)` links, breaking VitePress builds.
RSpec.describe 'Admonition xref and bibliography italic', type: :integration do
  describe 'cross-reference inside admonition' do
    let(:adoc) { "NOTE: See <<figureC-1>> for details.\n" }

    it 'CoreModel captures a CrossReferenceElement inside the AnnotationBlock' do
      core = Coradoc.parse(adoc, format: :asciidoc)
      block = core.children.first

      expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(block.children.map(&:class)).to include(Coradoc::CoreModel::CrossReferenceElement)
    end

    it 'VitePress renders the xref as a Markdown link inside :::note' do
      core = Coradoc.parse(adoc, format: :asciidoc)
      md = Coradoc.serialize(core, to: :markdown, markdown_flavor: :vitepress)

      expect(md).to include(':::note')
      expect(md).to include('[figureC-1](#figureC-1)')
      expect(md).not_to include('<<figureC-1>>')
      expect(md).not_to include('#<Coradoc')
    end

    it 'GitHub-flavor admonition also preserves the xref' do
      core = Coradoc.parse(adoc, format: :asciidoc)
      md = Coradoc.serialize(core, to: :markdown, markdown_flavor: :gfm)

      expect(md).to include('> **NOTE:**')
      expect(md).to include('[figureC-1](#figureC-1)')
      expect(md).not_to include('#<Coradoc')
    end
  end

  describe 'italic text inside bibliography entry' do
    let(:adoc) do
      "[bibliography]\n== References\n* [[[iso6322]]] _ISO 6322-1_: Cereals and pulses.\n"
    end

    it 'does not leak Inline::Italic inspect into Markdown output' do
      core = Coradoc.parse(adoc, format: :asciidoc)
      md = Coradoc.serialize(core, to: :markdown, markdown_flavor: :vitepress)

      expect(md).to include('ISO 6322-1')
      expect(md).not_to include('#<Coradoc')
      expect(md).not_to include('Inline::Italic')
    end
  end

  describe 'plain-text admonition (no inline formatting)' do
    it 'still serializes via the plain-content fast path' do
      core = Coradoc.parse("NOTE: Plain text only.\n", format: :asciidoc)
      md = Coradoc.serialize(core, to: :markdown, markdown_flavor: :vitepress)

      expect(md).to eq(":::note\nPlain text only.\n:::")
    end
  end
end
