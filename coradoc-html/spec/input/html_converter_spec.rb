# frozen_string_literal: true

require 'spec_helper'
require 'leptris'

RSpec.describe Coradoc::Html::HtmlConverter do
  describe '.to_core_model' do
    it 'converts a simple HTML string to CoreModel' do
      html = '<p>Hello World</p>'
      result = described_class.to_core_model(html)

      expect(result).to be_a(Array)
      expect(result.first).to be_a(Coradoc::CoreModel::Base)
    end

    it 'converts HTML with a heading to StructuralElement' do
      html = '<h1>Title</h1><p>Content</p>'
      result = described_class.to_core_model(html)

      expect(result).to be_a(Array)
      headings = result.select { |e| e.is_a?(Coradoc::CoreModel::StructuralElement) }
      expect(headings).not_to be_empty
    end

    it 'handles a Leptris::XML::Document input' do
      doc = Leptris::HTML.parse('<p>Leptris input</p>')
      result = described_class.to_core_model(doc)

      expect(result).to be_a(Array)
      expect(result.first).to be_a(Coradoc::CoreModel::Base)
    end

    it 'handles a Leptris::XML::Leptris node input' do
      doc = Leptris::HTML.parse('<p>Leptris node input</p>')
      node = doc.at('p')
      result = described_class.to_core_model(node)

      expect(result).to be_a(Coradoc::CoreModel::Base)
    end

    it 'returns nil for empty input' do
      result = described_class.to_core_model('')
      expect(result).to be_nil
    end

    describe 'html_version option' do
      it 'defaults to the html4 lane (Nokogiri tree parity)' do
        doc = described_class.html_parse('<table><td>x</td></table>')
        expect(doc.at_css('table').children.map(&:name)).to eq(%w[td])
      end

      it ':html5 selects the WHATWG engine with implied tbody/tr' do
        result = described_class.to_core_model(
          '<table><td>x</td></table>', html_version: :html5
        )
        expect(result.first).to be_a(Coradoc::CoreModel::Table)
      end

      it ':html5 does not synthesize an empty document header' do
        result = described_class.to_core_model('<p>x</p>', html_version: :html5)
        expect(result).not_to include(an_instance_of(Coradoc::CoreModel::DocumentElement))
      end

      it ':html5 keeps a titled document header' do
        html = '<html><head><title>T</title></head><body><p>x</p></body></html>'
        result = described_class.to_core_model(html, html_version: :html5)
        header = result.find { |e| e.is_a?(Coradoc::CoreModel::DocumentElement) }
        expect(header&.title&.to_s).to eq('T')
      end
    end

    it 'processes content through Postprocessor' do
      html = '<p>Text</p>'
      result = described_class.to_core_model(html)
      expect(result).not_to be_nil
    end
  end

  describe '.track_time' do
    it 'returns the block result when timing is disabled' do
      result = described_class.track_time('test task') { 42 }
      expect(result).to eq(42)
    end
  end

  describe '.prepare_plugin_instances' do
    it 'creates instances from config plugins when none provided' do
      instances = described_class.prepare_plugin_instances({})
      expect(instances).to be_an(Array)
    end

    it 'uses provided plugin_instances from options' do
      plugin = Coradoc::Html::Plugin.new
      instances = described_class.prepare_plugin_instances(plugin_instances: [plugin])
      expect(instances).to eq([plugin])
    end
  end
end
