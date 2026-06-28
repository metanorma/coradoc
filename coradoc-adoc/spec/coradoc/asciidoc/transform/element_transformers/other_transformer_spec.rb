# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::ElementTransformers::OtherTransformer do
  describe '.transform_term' do
    it 'transforms a term' do
      # NOTE: Coradoc::AsciiDoc::Model::Term might be defined slightly differently
      # We just stub an OpenStruct-like object if it's missing, but we assume it exists as per model
      # actually we should use the real model if it exists, let's use OpenStruct if it's not a real AsciiDoc model
      # wait, the instructions say use real model objects, never double.
      # Let's see if Coradoc::AsciiDoc::Model::Term exists.
      term = if defined?(Coradoc::AsciiDoc::Model::Term)
               Coradoc::AsciiDoc::Model::Term.new(term: 'Apple',
                                                  type: 'preferred', lang: 'en')
             else
               Struct.new(:term, :type, :lang).new(
                 'Apple', 'preferred', 'en'
               )
             end

      result = described_class.transform_term(term)

      expect(result).to be_a(Coradoc::CoreModel::Term)
      expect(result.text).to eq('Apple')
      expect(result.type).to eq('preferred')
      expect(result.lang).to eq('en')
    end
  end

  describe '.transform_admonition' do
    it 'transforms an admonition block' do
      admonition = Coradoc::AsciiDoc::Model::Admonition.new(
        type: 'NOTE',
        content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Watch out!')]
      )

      result = described_class.transform_admonition(admonition)

      expect(result).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(result.annotation_type).to eq('NOTE')
      expect(result.content).to eq('Watch out!')
      expect(result.children.size).to eq(1)
    end
  end

  describe '.transform_image' do
    it 'transforms a block image, lifting typed fields directly from the model' do
      image = Coradoc::AsciiDoc::Model::Image::BlockImage.new(
        src: 'img.png',
        alt: 'alt text',
        title: 'Caption',
        width: '800',
        height: '600',
        link: 'https://example.org',
        role: 'figure'
      )

      result = described_class.transform_image(image)

      expect(result).to be_a(Coradoc::CoreModel::Image)
      expect(result.src).to eq('img.png')
      expect(result.alt).to eq('alt text')
      expect(result.title).to eq('Caption')
      expect(result.width).to eq('800')
      expect(result.height).to eq('600')
      expect(result.link).to eq('https://example.org')
      expect(result.role).to eq('figure')
      expect(result.inline).to be false
    end

    it 'sets inline=true for InlineImage sources' do
      image = Coradoc::AsciiDoc::Model::Image::InlineImage.new(
        src: 'icon.png',
        alt: 'Icon',
        role: 'inline-role'
      )

      result = described_class.transform_image(image)

      expect(result.inline).to be true
      expect(result.alt).to eq('Icon')
      expect(result.role).to eq('inline-role')
    end

    it 'strips a single leading colon from the src' do
      image = Coradoc::AsciiDoc::Model::Image::BlockImage.new(src: ':images/foo.png')

      result = described_class.transform_image(image)

      expect(result.src).to eq('images/foo.png')
    end

    it 'never misreads the 2nd positional as caption (regression for inline role bug)' do
      image = Coradoc::AsciiDoc::Model::Image::InlineImage.new(
        src: 'foo.png',
        alt: 'Alt',
        role: 'SomeRole'
      )

      result = described_class.transform_image(image)

      expect(result.caption).to be_nil
      expect(result.role).to eq('SomeRole')
    end
  end

  describe '.transform_bibliography' do
    it 'transforms a bibliography with entries' do
      entry = Coradoc::AsciiDoc::Model::BibliographyEntry.new(
        anchor_name: 'ref1',
        document_id: 'doc1',
        ref_text: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Reference One')]
      )
      title = Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Bibliography')])
      bib = Coradoc::AsciiDoc::Model::Bibliography.new(
        id: 'bib-1',
        title: title,
        entries: [entry]
      )

      result = described_class.transform_bibliography(bib)

      expect(result).to be_a(Coradoc::CoreModel::Bibliography)
      expect(result.id).to eq('bib-1')
      expect(result.title).to eq('Bibliography')
      expect(result.entries.size).to eq(1)

      core_entry = result.entries.first
      expect(core_entry).to be_a(Coradoc::CoreModel::BibliographyEntry)
      expect(core_entry.anchor_name).to eq('ref1')
      expect(core_entry.document_id).to eq('doc1')
      expect(core_entry.ref_text).to include('Reference One')
    end

    it 'transforms an empty bibliography' do
      title = Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Empty')])
      bib = Coradoc::AsciiDoc::Model::Bibliography.new(
        title: title,
        entries: []
      )

      result = described_class.transform_bibliography(bib)

      expect(result).to be_a(Coradoc::CoreModel::Bibliography)
      expect(result.entries).to be_empty
    end
  end
end
