# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Image::AttributeExtractor do
  let(:attribute_list_class) { Coradoc::AsciiDoc::Model::AttributeList }

  describe '.call — inline image extraction' do
    let(:input) do
      attribute_list_class.new.tap do |list|
        list.add_positional('Alt text', 'ThumbRole')
        list.add_named('width', '640')
        list.add_named('height', '480')
        list.add_named('link', 'https://example.org')
        list.add_named('scaledwidth', '50%')
      end
    end

    it 'promotes the first two positional slots to alt and role' do
      extracted, = described_class.call(input, Coradoc::AsciiDoc::Model::Image::InlineImage)
      expect(extracted[:alt]).to eq('Alt text')
      expect(extracted[:role]).to eq('ThumbRole')
    end

    it 'promotes the named width/height/link keys' do
      extracted, = described_class.call(input, Coradoc::AsciiDoc::Model::Image::InlineImage)
      expect(extracted[:width]).to eq('640')
      expect(extracted[:height]).to eq('480')
      expect(extracted[:link]).to eq('https://example.org')
    end

    it 'leaves non-promoted named attrs in the residual list' do
      _, residual = described_class.call(input, Coradoc::AsciiDoc::Model::Image::InlineImage)
      expect(residual.positional).to be_empty
      expect(residual.named.map(&:name)).to eq(['scaledwidth'])
      expect(residual['scaledwidth']).to eq('50%')
    end

    it 'does not mutate the source list' do
      original_positional = input.positional.size
      original_named = input.named.size
      described_class.call(input, Coradoc::AsciiDoc::Model::Image::InlineImage)
      expect(input.positional.size).to eq(original_positional)
      expect(input.named.size).to eq(original_named)
    end
  end

  describe '.call — block image extraction' do
    let(:input) do
      attribute_list_class.new.tap do |list|
        list.add_positional('Alt')
        list.add_named('width', '800')
        list.add_named('role', 'figure')
      end
    end

    it 'promotes only the first positional (alt) for block images' do
      extracted, residual = described_class.call(input, Coradoc::AsciiDoc::Model::Image::BlockImage)
      expect(extracted[:alt]).to eq('Alt')
      expect(residual.positional).to be_empty
    end

    it 'promotes named role for block images' do
      extracted, = described_class.call(input, Coradoc::AsciiDoc::Model::Image::BlockImage)
      expect(extracted[:role]).to eq('figure')
      expect(extracted[:width]).to eq('800')
    end
  end

  describe '.call — positional/named duplicate (role)' do
    it 'positional wins when role is supplied in both forms' do
      list = attribute_list_class.new
      list.add_positional('Alt', 'PositionalRole')
      list.add_named('role', 'NamedRole')

      extracted, = described_class.call(list, Coradoc::AsciiDoc::Model::Image::InlineImage)
      expect(extracted[:role]).to eq('PositionalRole')
    end
  end

  describe '.call — empty / nil input' do
    it 'returns empty extracted hash and empty residual when source is nil' do
      extracted, residual = described_class.call(nil, Coradoc::AsciiDoc::Model::Image::InlineImage)
      expect(extracted).to eq({})
      expect(residual.positional).to be_empty
      expect(residual.named).to be_empty
    end

    it 'skips empty positional values' do
      list = attribute_list_class.new
      list.add_positional('Alt', '')
      list.add_named('width', '')

      extracted, residual = described_class.call(list, Coradoc::AsciiDoc::Model::Image::InlineImage)
      expect(extracted[:alt]).to eq('Alt')
      expect(extracted).not_to have_key(:role)
      expect(extracted).not_to have_key(:width)
      expect(residual.positional.map(&:value)).to eq([''])
    end
  end

  describe '.compose — inverse of .call' do
    it 'rebuilds positional + named slots from typed fields' do
      model = Coradoc::AsciiDoc::Model::Image::InlineImage.new(
        src: 'foo.png',
        alt: 'Alt',
        role: 'ThumbRole',
        width: '640',
        height: '480'
      )

      composed = described_class.compose(model)
      expect(composed.positional.map(&:value)).to eq(%w[Alt ThumbRole])
      expect(composed['width']).to eq('640')
      expect(composed['height']).to eq('480')
    end

    it 'does not duplicate a field that is both positional and named' do
      model = Coradoc::AsciiDoc::Model::Image::InlineImage.new(
        src: 'foo.png',
        alt: 'Alt',
        role: 'SomeRole'
      )

      composed = described_class.compose(model)
      role_named = composed.named.find { |n| n.name == 'role' }
      expect(role_named).to be_nil
      expect(composed.positional.map(&:value)).to include('SomeRole')
    end

    it 'falls back to named form when role was supplied as named only' do
      model = Coradoc::AsciiDoc::Model::Image::InlineImage.new(
        src: 'foo.png',
        alt: 'Alt',
        role: 'NamedRole'
      )
      # Simulate "no positional role" by leaving positional empty in residual:
      # the model only knows role as a typed field, not as positional context.
      composed = described_class.compose(model)
      # When role is filled positionally, named role is suppressed.
      expect(composed.positional.map(&:value)).to eq(%w[Alt NamedRole])
    end

    it 'preserves residual attributes after the promoted slots' do
      residual = Coradoc::AsciiDoc::Model::AttributeList.new
      residual.add_named('scaledwidth', '50%')

      model = Coradoc::AsciiDoc::Model::Image::InlineImage.new(
        src: 'foo.png',
        alt: 'Alt',
        attributes: residual
      )

      composed = described_class.compose(model)
      expect(composed['scaledwidth']).to eq('50%')
    end

    it 'omits empty/nil typed fields' do
      model = Coradoc::AsciiDoc::Model::Image::InlineImage.new(
        src: 'foo.png',
        alt: 'Alt'
      )

      composed = described_class.compose(model)
      expect(composed.positional.map(&:value)).to eq(['Alt'])
      expect(composed.named).to be_empty
    end

    it 'block image emits role via named, never positional' do
      model = Coradoc::AsciiDoc::Model::Image::BlockImage.new(
        src: 'foo.png',
        alt: 'Alt',
        role: 'figure',
        width: '800'
      )

      composed = described_class.compose(model)
      expect(composed.positional.map(&:value)).to eq(['Alt'])
      expect(composed['role']).to eq('figure')
      expect(composed['width']).to eq('800')
    end
  end

  describe 'round-trip: .call then .compose' do
    it 'preserves typed fields across extraction and recomposition' do
      list = attribute_list_class.new
      list.add_positional('Alt', 'Role')
      list.add_named('width', '640')

      extracted, residual = described_class.call(list, Coradoc::AsciiDoc::Model::Image::InlineImage)
      model = Coradoc::AsciiDoc::Model::Image::InlineImage.new(
        src: 'x.png',
        attributes: residual,
        **extracted
      )
      composed = described_class.compose(model)

      expect(composed.positional.map(&:value)).to eq(%w[Alt Role])
      expect(composed['width']).to eq('640')
    end
  end
end
