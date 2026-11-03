# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'coradoc-markdown.parg artifact parity with the Ruby DSL block grammar' do
  def grammar
    Coradoc::Markdown::Parser::Grammar
  end

  def normalize(obj)
    case obj
    when Parsanol::Slice then obj.to_s
    when Hash then obj.transform_values { |v| normalize(v) }
    when Array then obj.map { |v| normalize(v) }
    else obj
    end
  end

  def outcome
    [:ok, normalize(yield)]
  rescue StandardError => e
    [:err, e.class.to_s]
  end

  # The reference is the DSL grammar under the Ruby engine. The
  # production default (native) drops a fenced block's content
  # indentation when the fence itself is unindented (a zero-width
  # `fence_indent` capture leaks a stale span); the artifact, like the
  # Ruby engine, keeps it — see 'native DSL divergence' below.
  def dsl(input)
    Coradoc::Markdown::Parser::BlockParser.new.parse(input, mode: :ruby)
  end

  def self.fixture_paths
    repo_root = File.expand_path('../../../..', __dir__)
    Dir[File.expand_path('../../fixtures/**/*.text', __dir__)] +
      Dir[File.join(repo_root, 'BUGREPORT.model-driven', '*.md')]
  end

  it 'covers the whole markdown fixture corpus (guards against a vacuous run)' do
    expect(self.class.fixture_paths.size).to be >= 200
  end

  fixture_paths.each do |path|
    it "parses #{path.sub(%r{.*?/(coradoc-markdown|BUGREPORT)}, '\\1')} identically" do
      input = File.read(path)
      expect(outcome { grammar.parse(input) }).to eq(outcome { dsl(input) })
    end
  end

  describe 'block-nesting machinery' do
    {
      'lazy quote continuation' => "> bar\nbaz\n",
      'lazy nested quote' => "> > > foo\nbar\n",
      'lazy setext in quote' => "> foo\nbar\n===\n",
      'quote resumes after a nested quote' => "> foo\n>\n> > bar\n>> baz\n>\n> foo\n",
      'indented fence strips its own indent' => "  ```\n  a\n    b\n  ```\n",
      'tilde fence info' => "~~~ ruby\nx\n~~~\n",
      'backtick fence rejects backtick info' => "``` a`b\nx\n```\n"
    }.each do |name, input|
      it "parses '#{name}' identically" do
        expect(outcome { grammar.parse(input) }).to eq(outcome { dsl(input) })
      end
    end
  end

  describe 'native DSL divergence' do
    it 'keeps content indentation in an unindented fenced block, unlike the native DSL' do
      tree = normalize(grammar.parse("~~~\na\n  b\n~~~\n"))
      expect(tree).to eq([{ code_block: [{ ln: 'a' }, { ln: '  b' }] }])
    end
  end

  describe 'artifact freshness' do
    it 'was compiled from the committed .parg source' do
      expect(grammar.artifact.fresh_against?(File.read(grammar::SOURCE_PATH))).to be(true)
    end
  end
end
