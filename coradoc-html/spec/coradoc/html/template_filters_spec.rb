# frozen_string_literal: true

require 'spec_helper'
require 'liquid'

RSpec.describe Coradoc::Html::TemplateFilters do
  let(:filter_module) { described_class }

  describe '#escape_html' do
    it 'escapes HTML special characters' do
      template = Liquid::Template.parse('{{ content | escape_html }}')
      result = template.render('content' => '<b>Bold</b>')
      expect(result).to eq('&lt;b&gt;Bold&lt;/b&gt;')
    end

    it 'handles nil input' do
      template = Liquid::Template.parse('{{ content | escape_html }}')
      result = template.render('content' => nil)
      expect(result).to eq('')
    end
  end

  describe '#escape_attr' do
    it 'escapes attribute values' do
      template = Liquid::Template.parse('{{ value | escape_attr }}')
      result = template.render('value' => '"quoted"')
      expect(result).to eq('&quot;quoted&quot;')
    end
  end

  describe '#safe_json' do
    it 'produces valid JSON' do
      template = Liquid::Template.parse('{{ data | safe_json }}')
      data = { 'key' => 'value' }
      result = template.render('data' => data)
      parsed = JSON.parse(result)
      expect(parsed['key']).to eq('value')
    end

    it 'escapes script tags' do
      template = Liquid::Template.parse('{{ data | safe_json }}')
      result = template.render('data' => '</script><script>alert(1)')
      expect(result).not_to include('</script>')
    end
  end

  describe '#render_element' do
    it 'returns empty string for nil' do
      template = Liquid::Template.parse('{{ content | render_element }}')
      result = template.render('content' => nil)
      expect(result).to eq('')
    end
  end
end
