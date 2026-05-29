# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/renderer'
require 'coradoc/core_model'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'Template Integration' do
  let(:document) do
    Coradoc::CoreModel::DocumentElement.new(
      id: 'test-doc',
      title: 'Test Document'
    )
  end

  describe 'Renderer template customization' do
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
      FileUtils.mkdir_p(tmpdir)
      File.write(File.join(tmpdir, 'bibliography.liquid'), <<~LIQUID)
        <section id="{{ element.id }}" class="custom-bib">
          <h1>{{ element.title }}</h1>
          {% for entry in element.entries %}{{ entry | render_element }}{% endfor %}
        </section>
      LIQUID
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    it 'renders using custom templates from template_dirs' do
      renderer = Coradoc::Html::Renderer.new(template_dirs: [tmpdir])
      result = renderer.render(bibliography)
      expect(result).to include('custom-bib')
      expect(result).to include('TEST1')
    end

    it 'falls back to default templates when custom not found' do
      renderer = Coradoc::Html::Renderer.new(template_dirs: [tmpdir])
      # Block has no custom template, should use default
      block = Coradoc::CoreModel::Block.new(
        content: [Coradoc::CoreModel::TextContent.new(text: 'Hello')]
      )
      result = renderer.render(block)
      expect(result).to include('Hello')
    end

    it 'cascades from user dirs to default templates' do
      # Only override bibliography, other types use defaults
      renderer = Coradoc::Html::Renderer.new(template_dirs: [tmpdir])

      # Bibliography uses custom template
      bib_result = renderer.render(bibliography)
      expect(bib_result).to include('custom-bib')

      # Block uses default template
      block = Coradoc::CoreModel::Block.new(
        content: [Coradoc::CoreModel::TextContent.new(text: 'World')]
      )
      block_result = renderer.render(block)
      expect(block_result).to include('World')
      expect(block_result).not_to include('custom-bib')
    end
  end

  describe 'Renderer with template_dirs from global configuration' do
    after do
      Coradoc::Html.reset_configuration!
    end

    it 'uses template_dirs from global config' do
      tmpdir = Dir.mktmpdir
      begin
        FileUtils.mkdir_p(tmpdir)
        File.write(File.join(tmpdir, 'bibliography.liquid'), <<~LIQUID)
          <div class="global-template">{{ element.id }}</div>
        LIQUID

        Coradoc::Html.configure do |config|
          config.template_dirs = [tmpdir]
        end

        renderer = Coradoc::Html::Renderer.new(
          template_dirs: Coradoc::Html.configuration.template_dirs
        )
        expect(renderer.template_dirs).to eq([tmpdir])

        bib = Coradoc::CoreModel::Bibliography.new(id: 'test', level: 1)
        result = renderer.render(bib)
        expect(result).to include('global-template')
      ensure
        FileUtils.rm_rf(tmpdir)
      end
    end
  end
end
