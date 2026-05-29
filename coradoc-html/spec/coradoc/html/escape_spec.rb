# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::Escape do
  describe '.escape_html' do
    it 'escapes ampersands' do
      expect(described_class.escape_html('a & b')).to eq('a &amp; b')
    end

    it 'escapes angle brackets' do
      expect(described_class.escape_html('<div>')).to eq('&lt;div&gt;')
    end

    it 'escapes double quotes' do
      expect(described_class.escape_html('say "hello"')).to eq('say &quot;hello&quot;')
    end

    it 'escapes single quotes' do
      expect(described_class.escape_html("it's")).to eq('it&#39;s')
    end

    it 'escapes all entities in one string' do
      expect(described_class.escape_html('<a href="x&y">z\'s</a>')).to eq(
        '&lt;a href=&quot;x&amp;y&quot;&gt;z&#39;s&lt;/a&gt;'
      )
    end

    it 'returns empty string for nil' do
      expect(described_class.escape_html(nil)).to eq('')
    end

    it 'returns empty string for empty input' do
      expect(described_class.escape_html('')).to eq('')
    end

    it 'handles multi-byte characters' do
      expect(described_class.escape_html('café')).to eq('café')
    end

    it 'preserves already-escaped entities' do
      expect(described_class.escape_html('&amp;')).to eq('&amp;amp;')
    end

    it 'converts non-string objects via to_s' do
      expect(described_class.escape_html(42)).to eq('42')
    end
  end

  describe '.escape_attr' do
    it 'escapes ampersands' do
      expect(described_class.escape_attr('a & b')).to eq('a &amp; b')
    end

    it 'escapes double quotes' do
      expect(described_class.escape_attr('say "hello"')).to eq('say &quot;hello&quot;')
    end

    it 'escapes angle brackets' do
      expect(described_class.escape_attr('<script>')).to eq('&lt;script&gt;')
    end

    it 'does not escape single quotes' do
      expect(described_class.escape_attr("it's")).to eq("it's")
    end

    it 'returns empty string for nil' do
      expect(described_class.escape_attr(nil)).to eq('')
    end

    it 'converts non-string objects via to_s' do
      expect(described_class.escape_attr(true)).to eq('true')
    end
  end

  describe '.safe_json' do
    it 'JSON-encodes a hash' do
      result = described_class.safe_json({ 'key' => 'value' })
      expect(result).to eq('{"key":"value"}')
    end

    it 'escapes </script in JSON output' do
      result = described_class.safe_json({ 'html' => '</script><script>alert(1)' })
      expect(result).to include('<\\/script')
      expect(result).not_to include('</script>')
    end

    it 'passes through a pre-encoded string' do
      json = '{"a":1}'
      expect(described_class.safe_json(json)).to eq('{"a":1}')
    end
  end
end

RSpec.describe 'Coradoc::Html autoloads' do
  it 'resolves TemplateFilters constant' do
    expect(Coradoc::Html::TemplateFilters).to be_a(Module)
  end

  it 'resolves LayoutRenderer constant' do
    expect(Coradoc::Html::LayoutRenderer).to be_a(Class)
  end

  it 'resolves TocSerializer constant' do
    expect(Coradoc::Html::TocSerializer).to be_a(Class)
  end
end
