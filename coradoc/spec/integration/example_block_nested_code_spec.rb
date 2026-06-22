# frozen_string_literal: true

require 'spec_helper'

# Regression for BUG-codeblock-in-example-block.md.
#
# AsciiDoc example blocks (`====`) can contain other delimited blocks
# such as source blocks (`----`). The CoreModel parser correctly
# produces a nested ExampleBlock -> SourceBlock tree, but the Markdown
# transformer was flattening it via `flat_text`, which collapses
# everything to a single string and drops the code fence entirely.
#
# This spec exercises the round trip through CoreModel and asserts the
# nested code block is preserved with its fence, language, and content.
RSpec.describe 'Code block nested inside example block', type: :integration do
  let(:source) do
    <<~ADOC
      .Hint
      [%collapsible]
      ====
      Text before code.

      [source,asciidoc]
      ----
      <<anchor>>
      ----

      Text after code.
      ====
    ADOC
  end

  it 'CoreModel captures a SourceBlock inside the ExampleBlock' do
    core = Coradoc.parse(source, format: :asciidoc)
    example = core.children.first
    expect(example).to be_a(Coradoc::CoreModel::ExampleBlock)
    source_blocks = example.children.select { |c| c.is_a?(Coradoc::CoreModel::SourceBlock) }
    expect(source_blocks.length).to eq(1)
    expect(source_blocks.first.language).to eq('asciidoc')
    expect(source_blocks.first.content).to eq('<<anchor>>')
  end

  it 'VitePress output preserves the code block with fence and content' do
    md = Coradoc.serialize(
      Coradoc.parse(source, format: :asciidoc),
      to: :markdown, markdown_flavor: :vitepress
    )
    expect(md).to include(':::details Example: Hint')
    expect(md).to include('Text before code.')
    expect(md).to include('Text after code.')
    expect(md).to include("```asciidoc\n<<anchor>>\n```")
  end

  it 'default Markdown output also preserves the nested code block' do
    md = Coradoc.serialize(
      Coradoc.parse(source, format: :asciidoc),
      to: :markdown
    )
    expect(md).to include('<div class="example">')
    expect(md).to include('Text before code.')
    expect(md).to include('Text after code.')
    expect(md).to include("```asciidoc\n<<anchor>>\n```")
  end

  it 'does not collapse text and code onto a single line' do
    md = Coradoc.serialize(
      Coradoc.parse(source, format: :asciidoc),
      to: :markdown, markdown_flavor: :vitepress
    )
    expect(md).not_to match(/Text before code\.<<anchor>>/)
    expect(md).not_to match(/<<anchor>>Text after code\./)
  end
end
