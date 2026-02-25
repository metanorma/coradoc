# frozen_string_literal: true

require 'spec_helper'
require 'benchmark'

RSpec.describe 'Performance Benchmarks', type: :benchmark do
  # Skip benchmarks unless explicitly requested
  before(:all) do
    skip 'Benchmarks only run with BENCHMARK=true' unless ENV['BENCHMARK'] == 'true'
    require 'coradoc/html'
    require 'coradoc/markdown'
  end

  describe 'Markdown Parsing' do
    let(:small_markdown) { "# Title\n\n#{'Paragraph ' * 10}" }
    let(:medium_markdown) { "# Title\n\n#{'Paragraph content. ' * 100}\n\n## Section\n\n#{'More content. ' * 100}" }
    let(:large_markdown) do
      content = "# Large Document\n\n"
      50.times do |i|
        content += "## Section #{i}\n\n"
        content += 'Paragraph content here. ' * 20
        content += "\n\n"
        content += "* Item 1\n* Item 2\n* Item 3\n\n"
      end
      content
    end

    it 'parses small documents quickly' do
      result = Benchmark.measure do
        100.times { Coradoc::Markdown.parse(small_markdown) }
      end

      expect(result.real).to be < 5.0 # 100 parses in under 5 seconds
      puts "\nSmall Markdown (100 iterations): #{result.real.round(3)}s"
    end

    it 'parses medium documents efficiently' do
      result = Benchmark.measure do
        10.times { Coradoc::Markdown.parse(medium_markdown) }
      end

      expect(result.real).to be < 2.0 # 10 parses in under 2 seconds
      puts "\nMedium Markdown (10 iterations): #{result.real.round(3)}s"
    end

    it 'parses large documents without excessive memory' do
      memory_before = `ps -o rss= -p #{Process.pid}`.to_i

      result = Benchmark.measure do
        5.times { Coradoc::Markdown.parse(large_markdown) }
      end

      memory_after = `ps -o rss= -p #{Process.pid}`.to_i
      memory_growth = (memory_after - memory_before) / 1024 # MB

      expect(result.real).to be < 5.0
      expect(memory_growth).to be < 100 # Less than 100MB growth
      puts "\nLarge Markdown (5 iterations): #{result.real.round(3)}s, Memory: #{memory_growth}MB"
    end
  end

  describe 'Format Conversion' do
    let(:markdown_content) do
      "# Document Title\n\n" \
        "## Introduction\n\n" \
        "This is a paragraph with **bold** and *italic* text.\n\n" \
        "## Features\n\n" \
        "* Feature 1\n* Feature 2\n* Feature 3\n\n" \
        "## Code Example\n\n" \
        "```ruby\ndef hello\n  puts 'world'\nend\n```\n"
    end

    it 'converts Markdown to HTML efficiently' do
      result = Benchmark.measure do
        100.times { Coradoc.convert(markdown_content, from: :markdown, to: :html) }
      end

      expect(result.real).to be < 10.0 # 100 conversions in under 10 seconds
      puts "\nMarkdown to HTML (100 iterations): #{result.real.round(3)}s"
    end

    it 'round-trips through CoreModel efficiently' do
      result = Benchmark.measure do
        50.times do
          core = Coradoc.parse(markdown_content, format: :markdown)
          Coradoc.serialize(core, to: :html)
        end
      end

      expect(result.real).to be < 5.0
      puts "\nRound-trip via CoreModel (50 iterations): #{result.real.round(3)}s"
    end
  end

  describe 'CoreModel Creation' do
    it 'creates documents efficiently' do
      result = Benchmark.measure do
        1000.times do
          Coradoc::CoreModel::StructuralElement.new(
            element_type: 'document',
            title: 'Test Document',
            children: [
              Coradoc::CoreModel::Block.new(
                element_type: 'paragraph',
                content: 'Test content'
              )
            ]
          )
        end
      end

      expect(result.real).to be < 1.0
      puts "\nCoreModel Document creation (1000 iterations): #{result.real.round(3)}s"
    end

    it 'creates lists efficiently' do
      result = Benchmark.measure do
        500.times do
          Coradoc::CoreModel::ListBlock.new(
            marker_type: 'unordered',
            items: (1..10).map do |i|
              Coradoc::CoreModel::ListItem.new(content: "Item #{i}", marker: '*')
            end
          )
        end
      end

      expect(result.real).to be < 1.0
      puts "\nCoreModel List creation (500 iterations): #{result.real.round(3)}s"
    end
  end

  describe 'HTML Rendering' do
    let(:complex_document) do
      Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Complex Document',
        children: [
          Coradoc::CoreModel::StructuralElement.new(
            element_type: 'section',
            level: 1,
            title: 'Section 1',
            children: [
              Coradoc::CoreModel::Block.new(
                element_type: 'paragraph',
                content: 'Paragraph content'
              ),
              Coradoc::CoreModel::ListBlock.new(
                marker_type: 'unordered',
                items: [
                  Coradoc::CoreModel::ListItem.new(content: 'Item 1', marker: '*'),
                  Coradoc::CoreModel::ListItem.new(content: 'Item 2', marker: '*')
                ]
              ),
              Coradoc::CoreModel::Block.new(
                element_type: 'block',
                delimiter_type: '----',
                content: 'code here',
                language: 'ruby'
              )
            ]
          )
        ]
      )
    end

    it 'renders HTML efficiently' do
      result = Benchmark.measure do
        200.times { Coradoc::Html.serialize_static(complex_document) }
      end

      expect(result.real).to be < 5.0
      puts "\nHTML Rendering (200 iterations): #{result.real.round(3)}s"
    end
  end
end
