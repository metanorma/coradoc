# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Attribute reference resolution', type: :integration do
  describe 'Coradoc.parse resolves {name} against document attributes' do
    it 'substitutes a known attribute reference inside paragraph content' do
      adoc = ":foo: Bar Value\n\nHello {foo} world.\n"
      core = Coradoc.parse(adoc, format: :asciidoc)

      para = core.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      expect(para.content).to eq('Hello  Bar Value world.')

      inline_texts = para.children.map { |c| c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil }.compact
      expect(inline_texts).to include('Bar Value')
      expect(inline_texts).not_to include('{foo}')
    end

    it 'leaves unknown references untouched for round-trip' do
      adoc = "Hello {undefined_attr} world.\n"
      core = Coradoc.parse(adoc, format: :asciidoc)

      para = core.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      expect(para.content).to include('{undefined_attr}')
    end

    it 'resolves references inside list items' do
      adoc = ":name: Coradoc\n\n* Item referring to {name}\n"
      core = Coradoc.parse(adoc, format: :asciidoc)

      list = core.children.find { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(list).not_to be_nil
      item_text = list.items.first.children.map(&:to_s).join
      expect(item_text).to include('Coradoc')
      expect(item_text).not_to include('{name}')
    end

    it 'resolves references inside table cells' do
      adoc = ":val: 42\n\n|===\n| Key | Value\n| answer | {val}\n|===\n"
      core = Coradoc.parse(adoc, format: :asciidoc)

      table = core.children.find { |c| c.is_a?(Coradoc::CoreModel::Table) }
      expect(table).not_to be_nil
      last = table.rows.last.cells.last
      expect(last.content.to_s).to include('42')
      expect(last.content.to_s).not_to include('{val}')
    end

    it 'resolves references in document with no attributes (no-op)' do
      adoc = "Just plain text, no macros.\n"
      core = Coradoc.parse(adoc, format: :asciidoc)

      para = core.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      expect(para.content).to eq('Just plain text, no macros.')
    end
  end

  describe Coradoc::CoreModel::AttributeReferenceResolver do
    it 'returns the original tree when attributes are empty' do
      para = Coradoc::CoreModel::ParagraphBlock.new(content: 'Hello {foo}')
      result = described_class.call([para], Coradoc::CoreModel::Metadata.new)
      expect(result.first.content).to eq('Hello {foo}')
    end

    it 'does not mutate the input' do
      inline = Coradoc::CoreModel::InlineElement.new(
        format_type: 'attribute_reference',
        target: 'foo',
        content: '{foo}'
      )
      para = Coradoc::CoreModel::ParagraphBlock.new(
        content: 'Hello {foo}',
        children: [inline]
      )
      attrs = Coradoc::CoreModel::Metadata.new
      attrs['foo'] = 'Bar'

      described_class.call([para], attrs)

      expect(inline).to be_a(Coradoc::CoreModel::InlineElement)
      expect(inline.format_type).to eq('attribute_reference')
      expect(para.content).to eq('Hello {foo}')
    end
  end
end
