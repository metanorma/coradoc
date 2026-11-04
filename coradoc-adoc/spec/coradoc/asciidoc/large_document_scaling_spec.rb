# frozen_string_literal: true

require 'spec_helper'

# Large documents parsed superlinearly (coradoc#308): every table cell was
# re-parsed with the slow Ruby-DSL atoms, and recovering the line of each
# element re-sliced and re-counted the whole source prefix. The cell
# re-parse now runs through the compiled artifact's text_any/list entries
# and line_and_column uses a per-source newline index. Both must stay
# identical to the code they replaced.
RSpec.describe 'Large document scaling (#308)' do
  let(:parser_module) { Coradoc::AsciiDoc::Parser }

  describe 'PositionedString#line_and_column' do
    let(:source) { "first\n日本語 line\n\nlast é line\nend" }

    it 'matches Parsanol::Slice for every byte offset on a char boundary' do
      offsets = (0..source.bytesize).select { |i| source.byteslice(i, 1)&.valid_encoding? || i == source.bytesize }
      offsets.each do |offset|
        expected = Parsanol::Slice.new(offset, '', source).line_and_column
        actual = parser_module::PositionedString.new('', byte_position: offset, source_input: source).line_and_column
        expect(actual).to eq(expected), "offset #{offset}: expected #{expected}, got #{actual}"
      end
    end

    it 'raises without a source input' do
      expect { parser_module::PositionedString.new('x').line_and_column }.to raise_error(ArgumentError)
    end
  end

  describe 'table cell re-parse through the artifact' do
    let(:dsl) { parser_module::Base.new }

    def materialize(&)
      parser_module::TreeMaterializer.convert(yield)
    end

    def plain(node)
      case node
      when String then node.to_s
      when Hash then node.transform_values { |v| plain(v) }
      when Array then node.map { |v| plain(v) }
      else node
      end
    end

    [
      'plain text',
      'hello *bold* and _italic_ and `mono` text',
      'see <<ref>> and link:foo[bar] tail',
      '日本語 `code` _it_　end'
    ].each do |text|
      it "parses #{text.inspect} as text_any identically to the DSL" do
        expected = plain(materialize { dsl.text_any.parse(text) })
        actual = plain(parser_module::GrammarBackend.parse_entry('text_any', text))
        expect(actual).to eq(expected)
      end
    end

    it 'parses a list identically to the DSL' do
      text = "* one\n* two\n** nested\n* three"
      expected = plain(materialize { dsl.list.parse(text) })
      actual = plain(parser_module::GrammarBackend.parse_entry('list', text))
      expect(actual).to eq(expected)
    end

    it 'raises ParseFailed for multi-line text_any like the DSL' do
      expect { parser_module::GrammarBackend.parse_entry('text_any', "a\nb") }.to raise_error(Parsanol::ParseFailed)
    end
  end
end
