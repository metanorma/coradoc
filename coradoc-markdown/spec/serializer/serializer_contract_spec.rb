# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Serializer do
  describe 'error-handling contract' do
    describe 'top-level dispatch' do
      it 'raises ArgumentError for unknown element types' do
        unknown = Object.new

        expect { described_class.serialize(unknown) }.to raise_error(
          ArgumentError,
          /Unknown element type for serialization: Object/
        )
      end
    end

    describe 'inline content dispatch' do
      it 'raises ArgumentError for inline content without #to_md' do
        para = Coradoc::Markdown::Paragraph.new(
          children: [Object.new]
        )

        expect { described_class.serialize(para) }.to raise_error(
          ArgumentError,
          /Cannot serialize inline content of type Object/
        )
      end
    end

    describe 'Base#serialize_content' do
      it 'raises ArgumentError for content without #to_md' do
        base = Coradoc::Markdown::Base.new

        expect { base.serialize_content(Object.new) }.to raise_error(
          ArgumentError,
          /Cannot serialize Object to Markdown/
        )
      end

      it 'serializes strings directly' do
        base = Coradoc::Markdown::Base.new
        expect(base.serialize_content('hello')).to eq('hello')
      end

      it 'serializes nil as empty string' do
        base = Coradoc::Markdown::Base.new
        expect(base.serialize_content(nil)).to eq('')
      end

      it 'serializes arrays by joining' do
        base = Coradoc::Markdown::Base.new
        expect(base.serialize_content(['a', 'b'])).to eq('ab')
      end
    end
  end
end
