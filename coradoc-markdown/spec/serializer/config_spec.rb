# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Serializer::Config do
  describe 'defaults (from :gfm flavor)' do
    subject(:config) { described_class.new(flavor: :gfm) }

    it 'sets markdown_flavor to :gfm' do
      expect(config.markdown_flavor).to eq(:gfm)
    end

    it 'sets admonition_style to :github' do
      expect(config.admonition_style).to eq(:github)
    end

    it 'sets definition_list_nested to :html' do
      expect(config.definition_list_nested).to eq(:html)
    end

    it 'sets suppress_comments to true' do
      expect(config.suppress_comments).to eq(true)
    end

    it 'sets autolinks to true' do
      expect(config.autolinks).to eq(true)
    end
  end

  describe 'override precedence' do
    it 'lets caller override flavor defaults' do
      config = described_class.new(flavor: :gfm, admonition_style: :container)
      expect(config.admonition_style).to eq(:container)
    end

    it 'lets vitepress flavor default to :container admonition' do
      config = described_class.new(flavor: :vitepress)
      expect(config.admonition_style).to eq(:container)
    end
  end

  describe 'immutability' do
    it 'is frozen' do
      expect(described_class.new).to be_frozen
    end
  end

  describe 'validation' do
    it 'rejects unknown flavors' do
      expect { described_class.new(flavor: :nope) }.to raise_error(ArgumentError, /Unknown markdown_flavor/)
    end

    it 'rejects unknown admonition_style' do
      expect { described_class.new(admonition_style: :bogus) }.to raise_error(ArgumentError, /Unknown admonition_style/)
    end

    it 'rejects unknown definition_list_nested' do
      expect { described_class.new(definition_list_nested: :bogus) }.to raise_error(ArgumentError, /Unknown definition_list_nested/)
    end

    it 'rejects non-boolean suppress_comments' do
      expect { described_class.new(suppress_comments: :yes) }.to raise_error(ArgumentError, /suppress_comments must be boolean/)
    end

    it 'rejects non-boolean autolinks' do
      expect { described_class.new(autolinks: :yes) }.to raise_error(ArgumentError, /autolinks must be boolean/)
    end
  end

  describe '#with' do
    it 'returns a new config with merged overrides' do
      original = described_class.new(flavor: :gfm)
      derived = original.with(admonition_style: :container)
      expect(original.admonition_style).to eq(:github)
      expect(derived.admonition_style).to eq(:container)
    end
  end
end
