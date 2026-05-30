# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/layout_renderer'

RSpec.describe Coradoc::Html::LayoutRenderer do
  let(:document) { CoreModel::DocumentElement.new(title: 'Test Doc') }
  let(:body_html) { '<div>Content</div>' }
  let(:toc_data) { { entries: [], numbered: false } }

  describe '#render_static' do
    it 'renders static HTML fallback when no layout template' do
      html = described_class.new.render_static(document, body_html, {})
      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('Test Doc')
      expect(html).to include('Content')
    end

    it 'uses lang option' do
      html = described_class.new.render_static(document, body_html, { lang: 'fr' })
      expect(html).to include('lang="fr"')
    end

    it 'defaults to en language' do
      html = described_class.new.render_static(document, body_html, {})
      expect(html).to include('lang="en"')
    end

    it 'escapes the title' do
      doc = CoreModel::DocumentElement.new(title: '<script>alert("xss")</script>')
      html = described_class.new.render_static(doc, body_html, {})
      expect(html).not_to include('<script>alert')
    end
  end

  describe '#render_spa' do
    it 'renders SPA HTML fallback', :requires_frontend_dist do
      html = described_class.new.render_spa(
        document,
        { dist_dir: File.join(__dir__, '..', '..', '..', 'frontend', 'dist') },
        body_html,
        toc_data
      )
      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('coradoc-app')
      expect(html).to include('window.CORADOC_DATA')
    end

    it 'raises when dist_dir is missing' do
      expect do
        described_class.new.render_spa(
          document,
          { dist_dir: '/nonexistent' },
          body_html,
          toc_data
        )
      end.to raise_error(ArgumentError, /dist directory not found/)
    end
  end
end
