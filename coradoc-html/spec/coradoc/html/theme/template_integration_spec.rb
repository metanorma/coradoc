# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/theme/classic_renderer'
require 'coradoc/html/theme/modern_renderer'
require 'coradoc/html/template_config'
require 'coradoc/core_model'
require 'tmpdir'
require 'fileutils'

RSpec.describe Coradoc::Html::Theme::ClassicRenderer do
  let(:document) do
    Coradoc::CoreModel::StructuralElement.new(
      id: 'test-doc',
      title: 'Test Document',
      element_type: 'document'
    )
  end

  after do
    Coradoc::Html.reset_configuration!
  end

  describe '#use_templates?' do
    it 'returns false by default' do
      renderer = described_class.new(document)
      expect(renderer.use_templates?).to be false
    end

    it 'returns true when use_templates option is set' do
      renderer = described_class.new(document, use_templates: true)
      expect(renderer.use_templates?).to be true
    end
  end

  describe '#template_renderer' do
    it 'returns nil when templates not enabled' do
      renderer = described_class.new(document)
      expect(renderer.template_renderer).to be_nil
    end

    it 'returns Renderer when templates enabled' do
      renderer = described_class.new(document, use_templates: true)
      expect(renderer.template_renderer).to be_a(Coradoc::Html::Renderer)
    end

    it 'uses global configuration for template_dirs' do
      Coradoc::Html.configure do |config|
        config.template_dirs = ['/global/templates']
      end

      renderer = described_class.new(document, use_templates: true)
      expect(renderer.template_renderer.template_dirs).to eq(['/global/templates'])
    end

    it 'uses per-render template_dirs over global' do
      Coradoc::Html.configure do |config|
        config.template_dirs = ['/global/templates']
      end

      renderer = described_class.new(document,
                                     use_templates: true,
                                     template_dirs: ['/override/templates'])

      expect(renderer.template_renderer.template_dirs).to eq(['/override/templates'])
    end
  end

  describe '#supported_features' do
    it 'includes template_rendering when templates enabled' do
      renderer = described_class.new(document, use_templates: true)
      expect(renderer.supported_features).to include(:template_rendering)
    end

    it 'excludes template_rendering when templates disabled' do
      renderer = described_class.new(document)
      expect(renderer.supported_features).not_to include(:template_rendering)
    end
  end

  describe '#render with templates' do
    let(:tmpdir) { Dir.mktmpdir }
    let(:bibliography) do
      Coradoc::CoreModel::Bibliography.new(
        id: 'bib',
        title: 'References',
        level: 1,
        entries: [
          Coradoc::CoreModel::BibliographyEntry.new(
            anchor_name: 'TEST1',
            document_id: 'ISO 1234',
            ref_text: 'Test reference.'
          )
        ]
      )
    end

    before do
      # Create custom template
      FileUtils.mkdir_p(tmpdir)
      File.write(File.join(tmpdir, 'bibliography.liquid'), <<~LIQUID)
        <section id="{{ id }}" class="custom-bib">
          <h1>{{ title }}</h1>
          {% for entry in entries %}{{ entry | render_element }}{% endfor %}
        </section>
      LIQUID
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    it 'renders using templates when enabled' do
      renderer = described_class.new(bibliography,
                                     use_templates: true,
                                     template_dirs: [tmpdir])

      result = renderer.render
      expect(result).to include('custom-bib')
      expect(result).to include('TEST1')
    end
  end
end

RSpec.describe Coradoc::Html::Theme::ModernRenderer do
  let(:document) do
    Coradoc::CoreModel::StructuralElement.new(
      id: 'test-doc',
      title: 'Test Document',
      element_type: 'document'
    )
  end

  after do
    Coradoc::Html.reset_configuration!
  end

  describe '#template_dirs' do
    it 'returns empty array by default' do
      renderer = described_class.new(document)
      expect(renderer.template_dirs).to eq([])
    end

    it 'uses option template_dirs when provided' do
      renderer = described_class.new(document, template_dirs: ['/custom'])
      expect(renderer.template_dirs).to eq(['/custom'])
    end

    it 'uses global configuration when no option' do
      Coradoc::Html.configure do |config|
        config.template_dirs = ['/global']
      end

      renderer = described_class.new(document)
      expect(renderer.template_dirs).to eq(['/global'])
    end
  end

  describe '#use_custom_templates?' do
    let(:tmpdir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(tmpdir)
    end

    it 'returns false when no template_dirs configured' do
      renderer = described_class.new(document)
      expect(renderer.use_custom_templates?).to be false
    end

    it 'returns true when template_dirs has existing directory' do
      renderer = described_class.new(document, template_dirs: [tmpdir])
      expect(renderer.use_custom_templates?).to be true
    end

    it 'returns false when template_dirs has non-existing directory' do
      renderer = described_class.new(document, template_dirs: ['/nonexistent'])
      expect(renderer.use_custom_templates?).to be false
    end
  end
end
