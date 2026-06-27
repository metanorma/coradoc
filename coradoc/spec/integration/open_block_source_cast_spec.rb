# frozen_string_literal: true

require 'spec_helper'

# Regression for BUG-open-block-delimiter.md.
#
# AsciiDoc allows casting an open block (`--`) to a verbatim block
# via positional attributes: `[source]`, `[listing]`, `[literal]`.
# The CoreModel transformer was previously always producing an
# OpenBlock, dropping the code fence entirely.
#
# This spec exercises the round trip through CoreModel and asserts
# the cast dispatches to the correct typed block. Plain open blocks
# (no cast attribute) continue to produce an OpenBlock.
RSpec.describe 'Open block cast to verbatim block', type: :integration do
  let(:source) do
    <<~ADOC
      [source,asciidoc]
      --
      [bibliography]
      == References

      * [[[ref1,1]]] <1> text <2>
      --
    ADOC
  end

  it 'CoreModel casts to a SourceBlock with language preserved' do
    core = Coradoc.parse(source, format: :asciidoc)
    block = core.children.first
    expect(block).to be_a(Coradoc::CoreModel::SourceBlock)
    expect(block.language).to eq('asciidoc')
  end

  it 'preserves content including callout markers as text' do
    core = Coradoc.parse(source, format: :asciidoc)
    block = core.children.first
    expect(block.content).to include('[[[ref1,1]]]')
    expect(block.content).to include('<1>')
    expect(block.content).to include('<2>')
  end

  it 'VitePress output emits a fenced code block' do
    md = Coradoc.serialize(
      Coradoc.parse(source, format: :asciidoc),
      to: :markdown, markdown_flavor: :vitepress
    )
    expect(md).to include("```asciidoc\n")
    expect(md).to include('[bibliography]')
    expect(md).to include('== References')
  end

  context 'with [listing] cast' do
    let(:source) do
      <<~ADOC
        [listing]
        --
        preformatted text
        --
      ADOC
    end

    it 'CoreModel casts to a ListingBlock' do
      core = Coradoc.parse(source, format: :asciidoc)
      block = core.children.first
      expect(block).to be_a(Coradoc::CoreModel::ListingBlock)
    end
  end

  context 'with [literal] cast' do
    let(:source) do
      <<~ADOC
        [literal]
        --
        literal content
        --
      ADOC
    end

    it 'CoreModel casts to a LiteralBlock' do
      core = Coradoc.parse(source, format: :asciidoc)
      block = core.children.first
      expect(block).to be_a(Coradoc::CoreModel::LiteralBlock)
    end
  end

  context 'without any cast attribute' do
    let(:source) do
      <<~ADOC
        --
        Plain open block content.
        --
      ADOC
    end

    it 'stays an OpenBlock' do
      core = Coradoc.parse(source, format: :asciidoc)
      block = core.children.first
      expect(block).to be_a(Coradoc::CoreModel::OpenBlock)
    end

    it 'renders content as plain text' do
      md = Coradoc.serialize(
        Coradoc.parse(source, format: :asciidoc),
        to: :markdown, markdown_flavor: :vitepress
      )
      expect(md).to include('Plain open block content.')
    end
  end

  context 'with non-verbatim cast attribute (e.g. [note])' do
    let(:source) do
      <<~ADOC
        [NOTE]
        --
        This is a note.
        --
      ADOC
    end

    it 'casts to an AnnotationBlock' do
      core = Coradoc.parse(source, format: :asciidoc)
      block = core.children.first
      expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(block.annotation_type).to eq('NOTE')
    end

    it 'VitePress renders as a container admonition' do
      md = Coradoc.serialize(
        Coradoc.parse(source, format: :asciidoc),
        to: :markdown, markdown_flavor: :vitepress
      )
      expect(md).to include(':::note')
      expect(md).to include('This is a note.')
      expect(md).to include(':::')
    end
  end
end
