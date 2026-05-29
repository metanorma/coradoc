# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Coradoc::Html::TemplateLocator do
  describe 'DEFAULT_TEMPLATE_DIR' do
    it 'is a frozen Pathname' do
      expect(described_class::DEFAULT_TEMPLATE_DIR).to be_a(Pathname)
      expect(described_class::DEFAULT_TEMPLATE_DIR).to be_frozen
    end

    it 'points to an existing directory' do
      expect(described_class::DEFAULT_TEMPLATE_DIR).to exist
    end

    it 'contains liquid templates' do
      templates = described_class::DEFAULT_TEMPLATE_DIR.glob('*.liquid')
      expect(templates).not_to be_empty
    end
  end

  describe '#find' do
    it 'finds a default template by name' do
      locator = described_class.new
      path = locator.find('bibliography')
      expect(path).to be_a(Pathname)
      expect(path.to_s).to end_with('bibliography.liquid')
    end

    it 'returns nil for non-existent template' do
      locator = described_class.new
      expect(locator.find('non_existent_xyz')).to be_nil
    end

    it 'caches results' do
      locator = described_class.new
      path1 = locator.find('bibliography')
      path2 = locator.find('bibliography')
      expect(path1).to equal(path2)
    end

    context 'with user directories' do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, 'core_model'))
        File.write(File.join(tmpdir, 'core_model', 'custom.liquid'), '<p>Custom</p>')
      end

      after do
        FileUtils.rm_rf(tmpdir)
      end

      it 'finds templates in user core_model/ subdir' do
        locator = described_class.new(user_dirs: [tmpdir])
        path = locator.find('custom')
        expect(path).to exist
        expect(path.to_s).to include('core_model')
      end

      it 'prefers user templates over default' do
        File.write(File.join(tmpdir, 'core_model', 'bibliography.liquid'), '<p>Override</p>')
        locator = described_class.new(user_dirs: [tmpdir])
        path = locator.find('bibliography')
        expect(path.to_s).to include(tmpdir)
      end
    end
  end

  describe '#exists?' do
    it 'returns true for existing template' do
      locator = described_class.new
      expect(locator.exists?('bibliography')).to be true
    end

    it 'returns false for non-existent template' do
      locator = described_class.new
      expect(locator.exists?('non_existent_xyz')).to be false
    end
  end

  describe '#available_templates' do
    it 'returns sorted list of template names' do
      locator = described_class.new
      templates = locator.available_templates
      expect(templates).to eq(templates.sort)
    end

    it 'includes bibliography' do
      locator = described_class.new
      expect(locator.available_templates).to include('bibliography')
    end
  end

  describe '#clear_cache' do
    it 'clears the cache so subsequent finds re-resolve' do
      locator = described_class.new
      locator.find('bibliography')
      locator.clear_cache
      # Cache is cleared - next find will re-resolve
      path = locator.find('bibliography')
      expect(path).to be_a(Pathname)
    end
  end

  describe 'canonical constant sharing' do
    it 'Renderer references the same DEFAULT_TEMPLATE_DIR' do
      expect(Coradoc::Html::Renderer::DEFAULT_TEMPLATE_DIR).to eq(
        described_class::DEFAULT_TEMPLATE_DIR
      )
    end

    it 'TemplateConfig references the same DEFAULT_TEMPLATE_DIR' do
      expect(Coradoc::Html::TemplateConfig::DEFAULT_TEMPLATE_DIR).to eq(
        described_class::DEFAULT_TEMPLATE_DIR
      )
    end
  end
end
