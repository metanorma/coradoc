# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/block_drop'

RSpec.describe Coradoc::Html::Drop::BlockDrop do
  let(:model) { CoreModel::Block.new }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#template_type' do
    it 'returns block' do
      expect(drop.template_type).to eq('block')
    end
  end

  describe '#semantic_type' do
    it 'returns paragraph for a basic block' do
      expect(drop.semantic_type).to eq('paragraph')
    end

    it 'returns consistent values across calls' do
      values = Array.new(10) { drop.semantic_type }
      expect(values.uniq).to eq(['paragraph'])
    end
  end

  describe '#html_tag' do
    it 'returns p for paragraph' do
      expect(drop.html_tag).to eq('p')
    end

    it 'returns pre for source_code block' do
      source = CoreModel::SourceBlock.new(language: 'ruby')
      expect(described_class.new(source).html_tag).to eq('pre')
    end

    it 'returns blockquote for quote' do
      quote = CoreModel::QuoteBlock.new
      expect(described_class.new(quote).html_tag).to eq('blockquote')
    end

    it 'returns div for example' do
      example = CoreModel::ExampleBlock.new
      expect(described_class.new(example).html_tag).to eq('div')
    end

    it 'returns aside for sidebar' do
      sidebar = CoreModel::SidebarBlock.new
      expect(described_class.new(sidebar).html_tag).to eq('aside')
    end

    it 'returns pre for literal' do
      literal = CoreModel::LiteralBlock.new
      expect(described_class.new(literal).html_tag).to eq('pre')
    end

    it 'returns hr for horizontal_rule' do
      hr = CoreModel::HorizontalRuleBlock.new
      expect(described_class.new(hr).html_tag).to eq('hr')
    end

    it 'returns pre for listing' do
      listing = CoreModel::ListingBlock.new
      expect(described_class.new(listing).html_tag).to eq('pre')
    end
  end

  describe '#id' do
    it 'returns the model id' do
      block = CoreModel::Block.new(id: 'my-block')
      expect(described_class.new(block).id).to eq('my-block')
    end

    it 'returns nil when no id' do
      expect(drop.id).to be_nil
    end
  end

  describe '#title' do
    it 'returns escaped title' do
      block = CoreModel::Block.new(id: 'b1', title: 'Example <em>title</em>')
      expect(described_class.new(block).title).to eq('Example &lt;em&gt;title&lt;/em&gt;')
    end

    it 'returns nil when no title' do
      expect(drop.title).to be_nil
    end
  end

  describe '#language' do
    it 'returns language from source block' do
      source = CoreModel::SourceBlock.new(language: 'ruby')
      expect(described_class.new(source).language).to eq('ruby')
    end
  end

  describe '#css_class' do
    it 'includes the semantic type' do
      expect(drop.css_class).to include('block-paragraph')
    end

    it 'includes example class for example blocks' do
      example = CoreModel::ExampleBlock.new
      cls = described_class.new(example).css_class
      expect(cls).to include('example')
    end
  end

  describe '#hidden?' do
    it 'returns true for comment blocks' do
      comment = CoreModel::CommentBlock.new
      expect(described_class.new(comment).hidden?).to be true
    end

    it 'returns false for paragraph blocks' do
      expect(drop.hidden?).to be false
    end
  end

  describe '#hr?' do
    it 'returns true for horizontal rule' do
      hr = CoreModel::HorizontalRuleBlock.new
      expect(described_class.new(hr).hr?).to be true
    end

    it 'returns false for paragraph' do
      expect(drop.hr?).to be false
    end
  end

  describe '#raw?' do
    it 'returns true for pass block' do
      pass = CoreModel::PassBlock.new
      expect(described_class.new(pass).raw?).to be true
    end

    it 'returns false for paragraph' do
      expect(drop.raw?).to be false
    end
  end
end
