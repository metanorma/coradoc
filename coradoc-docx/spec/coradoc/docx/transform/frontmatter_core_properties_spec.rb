# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'
require 'coradoc/asciidoc'
require 'coradoc/docx'

RSpec.describe 'DOCX frontmatter core properties' do
  let(:adoc_text) do
    <<~ADOC
      ---
      author: Jane Doe
      date: 2026-06-14
      description: A test doc
      subject: Schemas
      tags:
        - foo
        - bar
      ---
      = Hello

      World.
    ADOC
  end

  let(:core) { Coradoc::AsciiDoc.parse_to_core(adoc_text) }

  describe Coradoc::Docx::Transform::FrontmatterCoreProperties do
    let(:block) { core.children.first }

    describe '.extract' do
      it 'returns the FrontmatterBlock when present' do
        result = described_class.extract(core)
        expect(result).to be_a(Coradoc::CoreModel::FrontmatterBlock)
      end

      it 'returns nil for documents without a FrontmatterBlock' do
        plain = Coradoc::CoreModel::DocumentElement.new(
          title: 'No frontmatter',
          children: [Coradoc::CoreModel::ParagraphBlock.new(content: 'body')]
        )
        expect(described_class.extract(plain)).to be_nil
      end
    end

    describe '.apply' do
      it 'sets core properties on a Uniword DocumentBuilder' do
        builder = Uniword::Builder::DocumentBuilder.new
        described_class.apply(builder, block)
        model = builder.model

        expect(model.core_properties.creator).to eq('Jane Doe')
        expect(model.core_properties.subject).to eq('Schemas')
        expect(model.core_properties.description).to eq('A test doc')
        expect(model.core_properties.keywords).to eq('foo, bar')
        expect(model.core_properties.created).to eq('2026-06-14')
      end

      it 'is a no-op for nil block' do
        builder = Uniword::Builder::DocumentBuilder.new
        expect { described_class.apply(builder, nil) }.not_to raise_error
      end
    end
  end

  describe 'Coradoc::Docx::Transform::FromCoreModel.transform' do
    it 'populates core properties from frontmatter when transforming a DocumentElement' do
      doc = Coradoc::Docx::Transform::FromCoreModel.transform(core)
      cp = doc.core_properties

      expect(cp.title).to eq('Hello')
      expect(cp.creator).to eq('Jane Doe')
      expect(cp.subject).to eq('Schemas')
      expect(cp.description).to eq('A test doc')
      expect(cp.keywords).to eq('foo, bar')
      expect(cp.created).to eq('2026-06-14')
    end
  end
end
