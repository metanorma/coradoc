# frozen_string_literal: true

require 'spec_helper'

# Cross-format regression for BUG-nested-code-blocks.md. Outer source
# blocks (------) with shorter inner delimiters (----) must treat the
# inner delimiters as literal text, preserving structure and double
# curly braces through to Markdown/HTML output.
RSpec.describe 'Nested delimited blocks cross-format', type: :integration do
  let(:adoc) do
    <<~ADOC
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
  end

  it 'AsciiDoc → CoreModel preserves structure as verbatim content' do
    core = Coradoc.parse(adoc, format: :asciidoc)
    expect(core.children.size).to eq(1)
    src = core.children.first
    expect(src).to be_a(Coradoc::CoreModel::SourceBlock)
    expect(src.content).to include('[yaml2text,strings.yaml,arr]')
    expect(src.content).to include('----')
    expect(src.content).to include('{{item}}')
    expect(src.content).to include('{% for item in arr %}')
  end

  it 'AsciiDoc → Markdown preserves every line and double braces' do
    core = Coradoc.parse(adoc, format: :asciidoc)
    md = Coradoc.serialize(core, to: :markdown, markdown_flavor: :vitepress)

    expect(md).to include('```asciidoc')
    expect(md).to include('[yaml2text,strings.yaml,arr]')
    expect(md).to include('{% for item in arr %}')
    expect(md).to include('=== {{forloop.index0}} {{item}}')
    expect(md).to include('{% endfor %}')
    expect(md).not_to include('{ {') # corrupted double brace from attribute reference
  end

  it 'AsciiDoc → HTML preserves every line and double braces' do
    core = Coradoc.parse(adoc, format: :asciidoc)
    html = Coradoc.serialize(core, to: :html)

    expect(html).to include('[yaml2text,strings.yaml,arr]')
    expect(html).to include('{% for item in arr %}')
    expect(html).to include('{{item}}')
  end

  it 'AsciiDoc → AsciiDoc round-trip preserves the verbatim content' do
    core = Coradoc.parse(adoc, format: :asciidoc)
    out = Coradoc.serialize(core, to: :asciidoc)

    expect(out).to include('[source,asciidoc]')
    expect(out).to include('[yaml2text,strings.yaml,arr]')
    expect(out).to include('{{item}}')
    expect(out).to include('{% for item in arr %}')
  end
end
