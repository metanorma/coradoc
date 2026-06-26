# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'

RSpec.describe Coradoc::RelativePath do
  describe '.from' do
    it 'returns the target unchanged when output_key has no slashes' do
      expect(described_class.from('foo', to: '.vitepress/theme'))
        .to eq('.vitepress/theme')
    end

    it 'walks up one directory per segment in the output_key' do
      expect(described_class.from('author/iso/ref/foo', to: '.vitepress/theme'))
        .to eq('../../../.vitepress/theme')
    end

    it 'walks up only the right number of directories for one-segment keys' do
      expect(described_class.from('author/foo', to: '.vitepress/theme'))
        .to eq('../.vitepress/theme')
    end

    it 'returns the target unchanged when output_key is nil' do
      expect(described_class.from(nil, to: '.vitepress/theme'))
        .to eq('.vitepress/theme')
    end

    it 'composes the VitePress-shaped import path from the proposal' do
      # The real-world import line from FEATURE-template-renderer-with-filesystem.md
      import = described_class.from('author/iso/ref/foo',
                                    to: '.vitepress/theme/components/ProseMirrorContent.vue')
      expect(import)
        .to eq('../../../.vitepress/theme/components/ProseMirrorContent.vue')
    end

    it 'composes a JSON import path that includes the output_key itself' do
      output_key = 'author/iso/ref/document-attributes'
      json_import = described_class.from(
        output_key,
        to: ".vitepress/mirror-json/#{output_key}.json"
      )
      expect(json_import)
        .to eq('../../../.vitepress/mirror-json/author/iso/ref/document-attributes.json')
    end

    it 'is a pure function: same inputs, same output (no state)' do
      expect(described_class.from('a/b/c', to: 'x')).to eq('../../x')
    end
  end
end
