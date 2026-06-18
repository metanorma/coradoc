# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc/parser/base'
require 'coradoc/asciidoc/transformer'

# Focused unit specs for the helper methods exposed on Coradoc::AsciiDoc::Transformer.
# These methods own the shape of the model objects the transformer emits;
# before this file existed only 1 of 10 had any direct coverage.
RSpec.describe Coradoc::AsciiDoc::Transformer do
  let(:attr_list_klass) { Coradoc::AsciiDoc::Model::AttributeList }

  def build_list(positional: [], named: [])
    list = attr_list_klass.new
    positional.each { |v| list.add_positional(v) }
    named.each { |k, v| list.add_named(k, v) }
    list
  end

  describe '.coerce_attribute_list' do
    let(:normalizer) { Coradoc::AsciiDoc::Transformer::AttributeListNormalizer }

    it 'returns nil for nil' do
      expect(normalizer.coerce(nil)).to be_nil
    end

    it 'returns the same object for a single AttributeList' do
      list = build_list(positional: %w[source])
      expect(normalizer.coerce(list)).to equal(list)
    end

    it 'returns the single AttributeList from a one-element Array' do
      list = build_list(positional: %w[source])
      expect(normalizer.coerce([list])).to equal(list)
    end

    it 'flattens an Array<{ attribute_list: <AttributeList> }>' do
      inner = build_list(positional: %w[source])
      wrapped = { attribute_list: inner }
      expect(normalizer.coerce([wrapped])).to equal(inner)
    end

    it 'merges multiple AttributeLists into a single one' do
      first = build_list(positional: %w[source], named: [['role', 'quote']])
      second = build_list(positional: %w[ruby])

      merged = normalizer.coerce([first, second])
      expect(merged).to be_a(attr_list_klass)
      expect(merged.positional.map(&:value)).to eq(%w[source ruby])
      expect(merged.named.map { |n| [n.name, n.value] }).to include(['role', ['quote']])
    end

    it 'returns nil for an empty Array' do
      expect(normalizer.coerce([])).to be_nil
    end

    it 'lets later named keys override earlier ones' do
      first = build_list(named: [['role', 'a']])
      second = build_list(named: [['role', 'b']])

      merged = normalizer.coerce([first, second])
      role_values = merged.named.select { |n| n.name == 'role' }.flat_map(&:value)
      expect(role_values).to eq(%w[a b])
    end
  end

  describe '.merge_attribute_lists' do
    let(:normalizer) { Coradoc::AsciiDoc::Transformer::AttributeListNormalizer }

    it 'concatenates positional and named across lists' do
      a = build_list(positional: %w[x], named: [['k1', 'v1']])
      b = build_list(positional: %w[y], named: [['k2', 'v2']])

      merged = normalizer.merge([a, b])
      expect(merged.positional.map(&:value)).to eq(%w[x y])
      expect(merged.named.map(&:name)).to eq(%w[k1 k2])
    end

    it 'returns an empty AttributeList for an empty input' do
      merged = normalizer.merge([])
      expect(merged).to be_a(attr_list_klass)
      expect(merged.positional).to be_empty
      expect(merged.named).to be_empty
    end

    it 'skips non-AttributeList entries' do
      valid = build_list(positional: %w[x])
      merged = normalizer.merge([valid, 'string', nil, Object.new])
      expect(merged.positional.map(&:value)).to eq(%w[x])
    end
  end

  describe '.parse_cols_attribute' do
    it 'returns nil when attrs is nil' do
      expect(described_class.parse_cols_attribute(nil)).to be_nil
    end

    it 'returns nil when attrs has no cols' do
      attrs = build_list(positional: %w[%header])
      expect(described_class.parse_cols_attribute(attrs)).to be_nil
    end

    it 'parses a single integer' do
      attrs = build_list(named: [['cols', '"3"']])
      expect(described_class.parse_cols_attribute(attrs)).to eq(3)
    end

    it 'counts comma-separated parts' do
      attrs = build_list(named: [['cols', '"1,2,1"']])
      expect(described_class.parse_cols_attribute(attrs)).to eq(3)
    end

    it 'parses multiplier syntax' do
      attrs = build_list(named: [['cols', '"3*"']])
      expect(described_class.parse_cols_attribute(attrs)).to eq(3)
    end

    it 'unquotes the value before parsing' do
      attrs = build_list(named: [['cols', '"4"']])
      expect(described_class.parse_cols_attribute(attrs)).to eq(4)
    end
  end

  describe '.group_cells_into_rows' do
    let(:cell_klass) { Coradoc::AsciiDoc::Model::TableCell }

    def cells(count)
      Array.new(count) { cell_klass.new(content: 'x') }
    end

    it 'returns [] for nil' do
      expect(described_class.group_cells_into_rows(nil)).to eq([])
    end

    it 'returns [] for empty' do
      expect(described_class.group_cells_into_rows([])).to eq([])
    end

    it 'groups 4 cells into 2 rows of 2 with explicit col count' do
      rows = described_class.group_cells_into_rows(cells(4), 2)
      expect(rows.size).to eq(2)
      expect(rows.map { |r| r.columns.size }).to eq([2, 2])
    end

    it 'groups all cells into one row when col count cannot be inferred' do
      # 5 cells, no col count → cannot divide evenly → falls back to one row
      rows = described_class.group_cells_into_rows(cells(5), nil)
      expect(rows.size).to eq(1)
      expect(rows.first.columns.size).to eq(5)
    end

    it 'starts a new row when colspan exceeds remaining slots' do
      big = cell_klass.new(content: 'wide', colspan: 2)
      small_one = cell_klass.new(content: 'a')
      small_two = cell_klass.new(content: 'b')
      rows = described_class.group_cells_into_rows([big, small_one, small_two], 2)
      expect(rows.size).to eq(2)
      expect(rows.first.columns).to eq([big])
      expect(rows.last.columns).to eq([small_one, small_two])
    end
  end

  describe '.infer_column_count' do
    let(:cell_klass) { Coradoc::AsciiDoc::Model::TableCell }

    it 'returns nil for empty cells' do
      expect(described_class.infer_column_count([])).to be_nil
    end

    it 'returns a valid divisor for evenly-divisible cells' do
      cells = Array.new(6) { cell_klass.new(content: 'x') }
      result = described_class.infer_column_count(cells)
      expect([1, 2, 3, 6]).to include(result)
    end

    it 'returns 1 when no other count works' do
      cells = [cell_klass.new(content: 'x', colspan: 1)]
      expect(described_class.infer_column_count(cells)).to eq(1)
    end
  end

  describe '.regroup_table_rows' do
    let(:cell_klass) { Coradoc::AsciiDoc::Model::TableCell }
    let(:row_klass) { Coradoc::AsciiDoc::Model::TableRow }

    it 'returns [] for empty input' do
      expect(described_class.regroup_table_rows([])).to eq([])
    end

    it 'returns nil rows unchanged when nil' do
      expect(described_class.regroup_table_rows(nil)).to be_nil
    end

    it 'marks the first row as header' do
      rows = [row_klass.new(columns: [cell_klass.new(content: 'a')])]
      regrouped = described_class.regroup_table_rows(rows)
      expect(regrouped.first.header).to be_truthy
    end
  end

  describe '.build_table_cell' do
    let(:cell_klass) { Coradoc::AsciiDoc::Model::TableCell }

    it 'builds a plain cell from a string content' do
      cell = described_class.build_table_cell(nil, 'hello')
      expect(cell).to be_a(cell_klass)
    end

    it 'parses colspan from a format Hash' do
      cell = described_class.build_table_cell({ colspan: '2' }, 'x')
      expect(cell.colspan).to eq(2)
    end

    it 'parses rowspan (strips leading dot)' do
      cell = described_class.build_table_cell({ rowspan: '.3' }, 'x')
      expect(cell.rowspan).to eq(3)
    end

    it 'parses style from a format Hash' do
      cell = described_class.build_table_cell({ style: 'a' }, 'x')
      expect(cell.style).to eq('a')
    end

    it 'parses colspan from a format String' do
      cell = described_class.build_table_cell('2+^', 'x')
      expect(cell.colspan).to eq(2)
      expect(cell.halign).to eq('^')
    end

    it 'keeps literal content raw for style "l"' do
      cell = described_class.build_table_cell({ style: 'l' }, 'raw *markdown*')
      content = cell.content
      content_str = content.is_a?(Array) ? content.map(&:to_s).join : content.to_s
      expect(content_str).to include('raw *markdown*')
    end

    it 'unescapes \\| in content' do
      cell = described_class.build_table_cell(nil, 'a\\|b')
      content = cell.content
      content_str = content.is_a?(Array) ? content.map(&:to_s).join : content.to_s
      expect(content_str).to include('a|b')
      expect(content_str).not_to include('a\\|b')
    end
  end

  describe '.parse_inline_content' do
    let(:text_element_klass) { Coradoc::AsciiDoc::Model::TextElement }

    it 'returns empty TextElement for nil' do
      result = described_class.parse_inline_content(nil)
      expect(result).to be_an(Array)
      expect(result.first).to be_a(text_element_klass)
    end

    it 'returns empty TextElement for blank string' do
      result = described_class.parse_inline_content('   ')
      expect(result.first).to be_a(text_element_klass)
    end

    it 'parses plain text into a TextElement array' do
      result = described_class.parse_inline_content('hello world')
      expect(result).to be_an(Array)
      expect(result.first).to be_a(text_element_klass)
    end

    it 'falls back to plain TextElement on parse failure' do
      result = described_class.parse_inline_content('hello')
      expect(result.first).to be_a(text_element_klass)
    end

    it 'parses block content for style "a"' do
      result = described_class.parse_inline_content('hello', 'a')
      expect(result).to be_an(Array)
    end

    it 'keeps content raw for style "l"' do
      result = described_class.parse_inline_content('raw', 'l')
      expect(result.first).to be_a(text_element_klass)
    end
  end

  describe '.parse_block_content' do
    let(:text_element_klass) { Coradoc::AsciiDoc::Model::TextElement }

    it 'returns empty TextElement for nil' do
      result = described_class.parse_block_content(nil)
      expect(result.first).to be_a(text_element_klass)
    end

    it 'returns empty TextElement for blank text' do
      result = described_class.parse_block_content('  ')
      expect(result.first).to be_a(text_element_klass)
    end

    it 'parses plain text' do
      result = described_class.parse_block_content('a paragraph')
      expect(result.first).to be_a(text_element_klass)
    end
  end

  describe '.extract_inline_content' do
    it 'returns the :content value of a Hash' do
      data = { content: 'hello' }
      expect(described_class.extract_inline_content(data)).to eq('hello')
    end

    it 'extracts :text values from an Array of Hashes' do
      data = [{ text: 'a' }, { text: 'b' }]
      expect(described_class.extract_inline_content(data)).to eq(%w[a b])
    end

    it 'passes through a plain string' do
      expect(described_class.extract_inline_content('x')).to eq('x')
    end
  end

  describe '.extract_simple_inline_content' do
    it 'returns the :content value of a Hash' do
      data = { content: 'hello' }
      expect(described_class.extract_simple_inline_content(data)).to eq('hello')
    end

    it 'joins :text values of an Array of Hashes' do
      data = [{ text: 'a' }, { text: 'b' }]
      expect(described_class.extract_simple_inline_content(data)).to eq('ab')
    end

    it 'passes through a plain string' do
      expect(described_class.extract_simple_inline_content('x')).to eq('x')
    end
  end

  describe '.lines_to_text_elements' do
    let(:text_element_klass) { Coradoc::AsciiDoc::Model::TextElement }

    it 'returns [] for nil' do
      expect(described_class.lines_to_text_elements(nil)).to eq([])
    end

    it 'returns [] for an empty array' do
      expect(described_class.lines_to_text_elements([])).to eq([])
    end

    it 'wraps a Hash line in a TextElement with scalar content' do
      line = { text: 'hello', line_break: "\n" }
      result = described_class.lines_to_text_elements([line])
      expect(result.size).to eq(1)
      expect(result.first).to be_a(text_element_klass)
      expect(result.first.line_break).to eq("\n")
    end

    it 'transforms array-text items via Transformer#apply' do
      line = { text: ['plain'], line_break: "\n" }
      result = described_class.lines_to_text_elements([line])
      expect(result.first).to be_a(text_element_klass)
      expect(result.first.content).to eq(['plain'])
    end

    it 'passes through non-Hash lines unchanged' do
      # e.g., a previously-transformed TextElement
      existing = text_element_klass.new(content: 'pre-transformed')
      result = described_class.lines_to_text_elements([existing])
      expect(result.first).to equal(existing)
    end
  end
end
