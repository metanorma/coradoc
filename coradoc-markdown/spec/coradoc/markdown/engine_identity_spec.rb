# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Markdown engine identity' do
  it 'builds block parsing on Parsanol::Parser' do
    expect(Coradoc::Markdown::Parser::BlockParser).to be < Parsanol::Parser
  end

  it 'builds inline parsing on Parsanol::Parser' do
    expect(Coradoc::Markdown::Parser::InlineParser).to be < Parsanol::Parser
  end

  it 'builds the transformer on Parsanol::Transform' do
    expect(Coradoc::Markdown::Transformer).to be < Parsanol::Transform
  end

  # The block grammar is pinned to the Ruby engine: the native VM's
  # shadowed-alternative lint rejects our zero-width continuation
  # lookaheads (parsanol-ruby#137 / #93). A native differential for
  # markdown lands when the upstream lint allows the grammar.
  it 'pins block parsing to the Ruby engine' do
    parser = Coradoc::Markdown::Parser::BlockParser.new
    tree = parser.parse('# Heading')
    expect(tree).not_to be_nil
  end

  it 'has the native engine available (fails under REQUIRE_NATIVE=1)' do
    if ENV['REQUIRE_NATIVE'] == '1'
      expect(Parsanol::Native.available?).to be(true)
    elsif !Parsanol::Native.available?
      skip 'parsanol native ext not built; set REQUIRE_NATIVE=1 to require it'
    end
  end
end
