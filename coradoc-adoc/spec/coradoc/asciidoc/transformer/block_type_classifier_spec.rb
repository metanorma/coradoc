# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc/transformer'

RSpec.describe Coradoc::AsciiDoc::Transformer::BlockTypeClassifier do
  let(:base_opts) { { id: nil, title: nil, delimiter_len: 4, lines: [], ordering: [] } }
  let(:attr_list_klass) { Coradoc::AsciiDoc::Model::AttributeList }

  def list_with(named: {}, positional: [])
    list = attr_list_klass.new
    positional.each { |v| list.add_positional(v) }
    named.each { |k, v| list.add_named(k, v) }
    list
  end

  describe '.classify' do
    it 'maps ==== to Block::Example' do
      result = described_class.classify('====', base_opts, nil)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::Example)
    end

    it 'maps ---- to Block::SourceCode' do
      result = described_class.classify('----', base_opts, nil)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::SourceCode)
    end

    it 'maps ____ to Block::Quote' do
      result = described_class.classify('____', base_opts, nil)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::Quote)
    end

    it 'maps ++++ to Block::Pass' do
      result = described_class.classify('++++', base_opts, nil)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::Pass)
    end

    it 'maps **** to Block::Side' do
      result = described_class.classify('****', base_opts, nil)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::Side)
    end

    it 'maps exactly 2 dashes to Block::Open' do
      result = described_class.classify('--', base_opts.merge(delimiter_len: 2), nil)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::Open)
    end

    it 'maps 5+ dashes to Block::SourceCode (still a listing)' do
      result = described_class.classify('-----', base_opts.merge(delimiter_len: 5), nil)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::SourceCode)
    end

    it 'maps **** with reviewer attribute to Block::ReviewerComment' do
      attrs = list_with(named: { 'reviewer' => 'alice' })
      result = described_class.classify('****', base_opts, attrs)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::ReviewerComment)
    end

    it 'maps **** with non-reviewer attribute to Block::Side' do
      attrs = list_with(named: { 'role' => 'sidebar' })
      result = described_class.classify('****', base_opts, attrs)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::Side)
    end

    it 'maps **** with positional attribute to Block::Side (not ReviewerComment)' do
      attrs = list_with(positional: %w[sidebar])
      result = described_class.classify('****', base_opts, attrs)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::Side)
    end

    it 'returns nil for an unrecognized delimiter' do
      result = described_class.classify('~~~~', base_opts, nil)
      expect(result).to be_nil
    end

    it 'returns nil for 3 dashes (ambiguous between Open and SourceCode)' do
      result = described_class.classify('---', base_opts.merge(delimiter_len: 3), nil)
      expect(result).to be_nil
    end

    it 'passes opts through to the constructed model' do
      opts = base_opts.merge(id: 'myid', title: 'My Title', lines: ['line 1'])
      result = described_class.classify('====', opts, nil)
      expect(result.id.to_s).to eq('myid')
    end
  end
end
