# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/text_content_drop'

RSpec.describe Coradoc::Html::Drop::TextContentDrop do
  let(:model) { CoreModel::TextContent.new(text: 'Hello world') }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#text' do
    it 'returns escaped text' do
      expect(drop.text).to eq('Hello world')
    end

    it 'escapes HTML entities' do
      tc = CoreModel::TextContent.new(text: '<script>alert("xss")</script>')
      d = described_class.new(tc)
      expect(d.text).to eq('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;')
    end
  end

  describe '#template_type' do
    it 'returns text_content' do
      expect(drop.template_type).to eq('text_content')
    end
  end
end
