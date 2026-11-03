# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Markdown bound-vs-unbound differential (M2 BindingInflater seam)' do
  def inflater
    Coradoc::Markdown::Bindings.inflater
  end

  def self.fixture_paths
    repo_root = File.expand_path('../../../..', __dir__)
    Dir[File.expand_path('../../fixtures/**/*.text', __dir__)] +
      Dir[File.join(repo_root, 'BUGREPORT.model-driven', '*.md')]
  end

  # Block quotes flatten child models with #to_s, which prints the class
  # and object address; compare modulo both.
  def comparable(doc)
    doc.to_yaml.gsub(/#<Coradoc::Markdown::(?:Generated::)?(\w+):0x\h+>/, '#<\\1>')
  end

  def contains_rule?(node, key)
    case node
    when Hash then node.key?(key) || node.each_value.any? { |v| contains_rule?(v, key) }
    when Array then node.any? { |v| contains_rule?(v, key) }
    else false
    end
  end

  def blocks_of(doc, klass)
    doc.blocks.select { |b| b.instance_of?(klass) }
  end

  it 'binds exactly one rule (thematic break) to the schema-generated class' do
    doc = Coradoc::Markdown.parse("para\n\n---\n\nafter\n", bindings: inflater)
    rules = blocks_of(doc, Coradoc::Markdown::Generated::HorizontalRule)
    expect(rules.map(&:style)).to eq(['---'])
  end

  it 'leaves parsing untouched when no bindings are given' do
    doc = Coradoc::Markdown.parse("para\n\n---\n")
    expect(blocks_of(doc, Coradoc::Markdown::HorizontalRule).size).to eq(1)
    expect(blocks_of(doc, Coradoc::Markdown::Generated::HorizontalRule)).to be_empty
  end

  it 'routes unbound nodes through the residual transformer' do
    doc = Coradoc::Markdown.parse("# Title\n\npara\n", bindings: inflater)
    expect(doc.blocks.map(&:class)).to eq([Coradoc::Markdown::Heading, Coradoc::Markdown::Paragraph])
  end

  it 'reaches bound rules nested in containers' do
    doc = Coradoc::Markdown.parse("> a\n>\n> ---\n", bindings: inflater)
    expect(comparable(doc)).to eq(comparable(Coradoc::Markdown.parse("> a\n>\n> ---\n")))
  end

  it 'exercises the bound path over the corpus (guards against a vacuous run)' do
    hits = self.class.fixture_paths.count do |path|
      contains_rule?(Coradoc::Markdown.parse_ast(File.read(path)), :hr)
    end
    expect(hits).to be >= 4
  end

  {
    'dashes' => "a\n\n---\n\nb\n",
    'stars' => "***\n",
    'underscores' => "_ _ _\n\ntext\n",
    'after a list' => "- a\n- b\n\n---\n",
    'with an attribute list' => "---\n{:.rule}\n"
  }.each do |name, input|
    it "produces identical output for inline '#{name}'" do
      expect(comparable(Coradoc::Markdown.parse(input, bindings: inflater))).to eq(comparable(Coradoc::Markdown.parse(input)))
    end
  end

  fixture_paths.each do |path|
    it "produces identical output for #{path.sub(%r{.*?/(coradoc-markdown|BUGREPORT)}, '\\1')}" do
      input = File.read(path)
      unbound = Coradoc::Markdown.parse(input)
      bound = Coradoc::Markdown.parse(input, bindings: inflater)
      expect(comparable(bound)).to eq(comparable(unbound))
    end
  end
end
