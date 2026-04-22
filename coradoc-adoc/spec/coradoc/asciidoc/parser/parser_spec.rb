# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Parser::Base do
  describe '.parse' do
    context 'with empty input' do
      it 'parses empty string' do
        result = described_class.parse('')
        expect(result).to be_a(Hash)
      end
    end

    context 'with simple document' do
      it 'parses a simple paragraph' do
        result = described_class.parse('Hello world')
        expect(result).to be_a(Hash)
      end

      it 'parses multiple lines' do
        result = described_class.parse("Line one\nLine two")
        expect(result).to be_a(Hash)
      end
    end

    context 'with document attributes' do
      it 'parses attribute' do
        result = described_class.parse(':author: John Doe')
        expect(result).to be_a(Hash)
      end

      it 'parses multiple attributes' do
        result = described_class.parse(":author: John\n:revdate: 2024")
        expect(result).to be_a(Hash)
      end
    end

    context 'with sections' do
      it 'parses level 1 heading' do
        result = described_class.parse('= Document Title')
        expect(result).to be_a(Hash)
      end

      it 'parses level 2 heading' do
        result = described_class.parse('== Section Title')
        expect(result).to be_a(Hash)
      end
    end

    context 'with lists' do
      it 'parses unordered list' do
        result = described_class.parse("* Item 1\n* Item 2")
        expect(result).to be_a(Hash)
      end

      it 'parses ordered list' do
        result = described_class.parse(". Item 1\n. Item 2")
        expect(result).to be_a(Hash)
      end
    end

    context 'with inline formatting' do
      it 'parses bold text' do
        result = described_class.parse('This is *bold* text')
        expect(result).to be_a(Hash)
      end

      it 'parses italic text' do
        result = described_class.parse('This is _italic_ text')
        expect(result).to be_a(Hash)
      end

      it 'parses monospace text' do
        result = described_class.parse('This is `code` text')
        expect(result).to be_a(Hash)
      end
    end

    context 'with blocks' do
      it 'parses source block' do
        input = "----\ncode here\n----"
        result = described_class.parse(input)
        expect(result).to be_a(Hash)
      end

      it 'parses example block' do
        input = "====\nexample content\n===="
        result = described_class.parse(input)
        expect(result).to be_a(Hash)
      end

      it 'parses quote block' do
        input = "____\nquoted text\n____"
        result = described_class.parse(input)
        expect(result).to be_a(Hash)
      end
    end

    context 'with tables' do
      it 'parses simple table' do
        input = "|===\n|Cell 1 |Cell 2\n|==="
        result = described_class.parse(input)
        expect(result).to be_a(Hash)
      end
    end

    context 'with admonitions' do
      it 'parses NOTE admonition' do
        result = described_class.parse('NOTE: This is important')
        expect(result).to be_a(Hash)
      end

      it 'parses WARNING admonition' do
        result = described_class.parse('WARNING: Be careful')
        expect(result).to be_a(Hash)
      end
    end
  end

  describe 'inheritance' do
    it 'includes Parslet parser' do
      expect(described_class.ancestors).to include(Parslet::Parser)
    end
  end
end

RSpec.describe 'Parser Integration' do
  describe 'full document parsing' do
    it 'parses complete document with header and sections' do
      input = <<~ADOC
        = Document Title
        :author: John Doe

        == Introduction

        This is the introduction paragraph.

        == Features

        * Feature one
        * Feature two

        === Subsection

        Some content here.
      ADOC

      result = Coradoc::AsciiDoc::Parser::Base.parse(input)
      expect(result).to be_a(Hash)
    end
  end
end
