# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

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

    it 'handles a Nokogiri::XML::Document input' do
      doc = Nokogiri::HTML('<p>Nokogiri input</p>')
      result = described_class.to_core_model(doc)

      expect(result).to be_a(Array)
      expect(result.first).to be_a(Coradoc::CoreModel::Base)
    end

    it 'handles a Nokogiri::XML::Node input' do
      doc = Nokogiri::HTML('<p>Node input</p>')
      node = doc.at('p')
      result = described_class.to_core_model(node)

      expect(result).to be_a(Coradoc::CoreModel::Base)
    end

    it 'returns nil for empty input' do
      result = described_class.to_core_model('')
      expect(result).to be_nil
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
