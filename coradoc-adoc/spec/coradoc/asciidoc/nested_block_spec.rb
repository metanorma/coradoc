# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc nested delimited blocks' do
  def parse_to_core(adoc)
    Coradoc.parse(adoc, format: :asciidoc)
  end

  it 'treats shorter inner delimiters as literal text of the outer source block' do
    adoc = <<~ADOC
      [source,asciidoc]
      ------
      [yaml2text,strings.yaml,arr]
      ----
      {% for item in arr %}
      === {{forloop.index0}} {{item}}
      {% endfor %}
      ----
      ------
    ADOC

    core = parse_to_core(adoc)

    expect(core.children.size).to eq(1)
    src = core.children.first
    expect(src).to be_a(Coradoc::CoreModel::SourceBlock)
    expect(src.language).to eq('asciidoc')
    expect(src.content).to eq(<<~TEXT.chomp)
      [yaml2text,strings.yaml,arr]
      ----
      {% for item in arr %}
      === {{forloop.index0}} {{item}}
      {% endfor %}
      ----
    TEXT
  end

  it 'preserves double curly braces verbatim inside source blocks' do
    adoc = <<~ADOC
      [source,liquid]
      ------
      {% for x in arr %}
      {{ x }}
      {% endfor %}
      ------
    ADOC

    core = parse_to_core(adoc)
    src = core.children.first
    expect(src).to be_a(Coradoc::CoreModel::SourceBlock)
    expect(src.content).to include('{{ x }}')
    expect(src.content).to include('{% for x in arr %}')
  end

  it 'still parses shorter outer blocks normally' do
    adoc = <<~ADOC
      [source,ruby]
      ----
      puts "hi"
      ----
    ADOC

    core = parse_to_core(adoc)
    expect(core.children.first.content).to eq('puts "hi"')
  end
end
