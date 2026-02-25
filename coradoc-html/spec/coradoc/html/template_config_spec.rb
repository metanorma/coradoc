# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/template_config'
require 'tmpdir'
require 'fileutils'

RSpec.describe Coradoc::Html::TemplateConfig do
  describe '.new' do
    it 'accepts empty template_dirs' do
      config = described_class.new
      expect(config.template_dirs).to eq([])
    end

    it 'accepts template_dirs as strings' do
      config = described_class.new(template_dirs: ['/tmp/templates'])
      expect(config.template_dirs).to eq([Pathname.new('/tmp/templates')])
    end

    it 'accepts template_dirs as pathnames' do
      path = Pathname.new('/tmp/templates')
      config = described_class.new(template_dirs: [path])
      expect(config.template_dirs).to eq([path])
    end

    it 'converts single directory to array' do
      config = described_class.new(template_dirs: '/tmp/templates')
      expect(config.template_dirs).to be_an(Array)
    end
  end

  describe '#all_template_dirs' do
    it 'includes default template directory' do
      config = described_class.new
      expect(config.all_template_dirs).to include(described_class::DEFAULT_TEMPLATE_DIR)
    end

    it 'puts user directories before default' do
      config = described_class.new(template_dirs: ['/custom'])
      all_dirs = config.all_template_dirs
      expect(all_dirs.first).to eq(Pathname.new('/custom'))
      expect(all_dirs.last).to eq(described_class::DEFAULT_TEMPLATE_DIR)
    end
  end

  describe '.available_templates' do
    it 'returns an array of symbols' do
      templates = described_class.available_templates
      expect(templates).to be_an(Array)
      expect(templates).to all(be_a(Symbol))
    end

    it 'includes bibliography templates' do
      templates = described_class.available_templates
      expect(templates).to include(:bibliography)
      expect(templates).to include(:bibliography_entry)
    end
  end

  describe '.template_path_for' do
    it 'returns pathname for existing template' do
      path = described_class.template_path_for(:bibliography)
      expect(path).to be_a(Pathname)
      expect(path.to_s).to end_with('bibliography.liquid')
    end

    it 'returns nil for non-existent template' do
      path = described_class.template_path_for(:non_existent_template_xyz)
      expect(path).to be_nil
    end
  end

  describe '#template_exists?' do
    let(:config) { described_class.new }

    it 'returns true for existing default template' do
      expect(config.template_exists?(:bibliography)).to be true
    end

    it 'returns false for non-existent template' do
      expect(config.template_exists?(:non_existent_xyz)).to be false
    end

    context 'with custom template directory' do
      let(:tmpdir) { Dir.mktmpdir }
      let(:config) { described_class.new(template_dirs: [tmpdir]) }

      before do
        File.write(File.join(tmpdir, 'custom.liquid'), '<p>Custom</p>')
      end

      after do
        FileUtils.rm_rf(tmpdir)
      end

      it 'finds custom template' do
        expect(config.template_exists?(:custom)).to be true
      end
    end
  end

  describe '#find_template' do
    let(:config) { described_class.new }

    it 'finds default templates' do
      path = config.find_template(:bibliography)
      expect(path).to be_a(Pathname)
      expect(path.to_s).to end_with('bibliography.liquid')
    end

    it 'returns nil for non-existent template' do
      path = config.find_template(:non_existent_xyz)
      expect(path).to be_nil
    end

    context 'with custom template directory' do
      let(:tmpdir) { Dir.mktmpdir }
      let(:config) { described_class.new(template_dirs: [tmpdir]) }

      before do
        File.write(File.join(tmpdir, 'bibliography.liquid'), '<p>Custom</p>')
      end

      after do
        FileUtils.rm_rf(tmpdir)
      end

      it 'prefers custom template over default' do
        path = config.find_template(:bibliography)
        expect(path.to_s).to include(tmpdir)
      end
    end
  end

  describe '#reset!' do
    it 'clears all template directories' do
      config = described_class.new(template_dirs: ['/custom'])
      config.reset!
      expect(config.template_dirs).to eq([])
    end
  end

  describe '#with_dirs' do
    it 'creates a new config with merged directories' do
      config = described_class.new(template_dirs: ['/first'])
      new_config = config.with_dirs(['/second'])

      expect(config.template_dirs.map(&:to_s)).to eq(['/first'])
      expect(new_config.template_dirs.map(&:to_s)).to eq(['/first', '/second'])
    end
  end
end

RSpec.describe Coradoc::Html do
  after do
    described_class.reset_configuration!
  end

  describe '.configuration' do
    it 'returns a TemplateConfig instance' do
      expect(described_class.configuration).to be_a(Coradoc::Html::TemplateConfig)
    end

    it 'returns the same instance on repeated calls' do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to eq(config2)
    end
  end

  describe '.configure' do
    it 'yields the configuration object' do
      described_class.configure do |config|
        expect(config).to be_a(Coradoc::Html::TemplateConfig)
      end
    end

    it 'allows setting template_dirs' do
      described_class.configure do |config|
        config.template_dirs = ['/custom/templates']
      end

      expect(described_class.configuration.template_dirs.map(&:to_s)).to eq(['/custom/templates'])
    end
  end

  describe '.reset_configuration!' do
    it 'creates a new configuration instance' do
      original = described_class.configuration
      described_class.configure { |c| c.template_dirs = ['/test'] }

      described_class.reset_configuration!
      expect(described_class.configuration.template_dirs).to eq([])
      expect(described_class.configuration).not_to eq(original)
    end
  end

  describe '.available_templates' do
    it 'delegates to TemplateConfig.available_templates' do
      expect(described_class.available_templates).to eq(Coradoc::Html::TemplateConfig.available_templates)
    end

    it 'returns template names as symbols' do
      templates = described_class.available_templates
      expect(templates).to include(:bibliography)
      expect(templates).to include(:bibliography_entry)
    end
  end

  describe '.template_path_for' do
    it 'returns path for existing template' do
      path = described_class.template_path_for(:bibliography)
      expect(path).to be_a(Pathname)
      expect(path.to_s).to end_with('bibliography.liquid')
    end

    it 'returns nil for non-existent template' do
      path = described_class.template_path_for(:non_existent_xyz)
      expect(path).to be_nil
    end
  end
end
