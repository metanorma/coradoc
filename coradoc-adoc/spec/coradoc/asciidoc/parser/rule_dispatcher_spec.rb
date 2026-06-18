# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc/parser/base'

RSpec.describe Coradoc::AsciiDoc::Parser::RuleDispatcher do
  let(:parser_class) { Coradoc::AsciiDoc::Parser::Base }

  describe '.apply' do
    it 'is idempotent — re-applying does not double-wrap' do
      # Base has already been wrapped at load time. Calling apply again
      # must detect existing aliases and skip them; otherwise the second
      # alias_method would snapshot the dispatcher itself, causing
      # infinite recursion on the next dispatch.
      expect { described_class.apply(parser_class) }.not_to raise_error
      parser = parser_class.new
      expect { parser.section(2) }.not_to raise_error
    end

    it 'defines the alias_dispatch_* pattern for parameterized rules' do
      parser = parser_class.new
      expect(parser.respond_to?(:alias_dispatch_section)).to be(true)
    end

    it 'does not alias parameterless rules under the dispatch name' do
      # block(n_deep=3) is parameterized → wrapped via wrap_dispatch
      parser = parser_class.new
      expect(parser.respond_to?(:alias_dispatch_block)).to be(true)
    end
  end

  describe 'dispatch behavior' do
    it 'memoizes the same args+rule combination' do
      parser = parser_class.new
      first = parser.section(2)
      second = parser.section(2)
      expect(first).to be_a(Parslet::Atoms::Base)
      expect(second).to be_a(Parslet::Atoms::Base)
    end

    it 'handles different args to the same rule' do
      parser = parser_class.new
      expect { parser.section(2) }.not_to raise_error
      expect { parser.section(3) }.not_to raise_error
    end
  end

  describe 'end-to-end smoke' do
    it 'parses a simple document' do
      tree = parser_class.new.parse("= Title\n\nhello world\n")
      expect(tree).to be_a(Hash)
    end

    it 'does not wrap inherited methods like __send__' do
      expect { parser_class.new.section(2) }.not_to raise_error
    end
  end
end
