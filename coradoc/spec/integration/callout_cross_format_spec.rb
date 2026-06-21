# frozen_string_literal: true

require 'spec_helper'

# Cross-format regression for the AsciiDoc callout bug (BUG-callout-markers.md).
# VitePress compiles Markdown into Vue SFCs; literal `<1>` in the output
# triggers `SyntaxError: Element is missing end tag`. This spec pins the
# end-to-end behaviour: callouts become a numbered list and `<N>` markers
# are stripped from the code.
RSpec.describe 'Callout markers cross-format', type: :integration do
  let(:adoc_with_callout) do
    <<~ADOC
      [source,ruby]
      ----
      get '/hi' do <1>
      ----
      <1> Returns hello world
    ADOC
  end

  let(:adoc_with_multi_callouts) do
    <<~ADOC
      [source,ruby]
      ----
      get '/hi' do <1>
      puts "hello" <2>
      ----
      <1> Returns hello world
      <2> Prints greeting
    ADOC
  end

  describe 'AsciiDoc → Markdown (VitePress)' do
    it 'strips <N> from code and emits a numbered list of annotations' do
      core = Coradoc.parse(adoc_with_callout, format: :asciidoc)
      md = Coradoc.serialize(core, to: :markdown, markdown_flavor: :vitepress)

      expect(md).to eq("```ruby\nget '/hi' do\n```\n\n1. Returns hello world")
    end

    it 'emits ordered list items in callout order' do
      core = Coradoc.parse(adoc_with_multi_callouts, format: :asciidoc)
      md = Coradoc.serialize(core, to: :markdown, markdown_flavor: :vitepress)

      expect(md).to include("```ruby\nget '/hi' do\nputs \"hello\"\n```")
      expect(md).to include('1. Returns hello world')
      expect(md).to include('1. Prints greeting')
      expect(md).not_to include('<1>')
      expect(md).not_to include('<2>')
    end

    it 'produces Vue-safe output (no stray <N> tags)' do
      core = Coradoc.parse(adoc_with_callout, format: :asciidoc)
      md = Coradoc.serialize(core, to: :markdown, markdown_flavor: :vitepress)

      expect(md).not_to match(/<\d+>/)
    end
  end

  describe 'AsciiDoc → HTML' do
    it 'renders callouts as an ordered list after the code block' do
      core = Coradoc.parse(adoc_with_callout, format: :asciidoc)
      html = Coradoc.serialize(core, to: :html)

      expect(html).to include('<pre><code data-lang="ruby">get &#39;/hi&#39; do</code></pre>')
      expect(html).to include('<ol class="callouts">')
      expect(html).to include('<li value="1">Returns hello world</li>')
    end

    it 'strips callout markers from rendered code' do
      core = Coradoc.parse(adoc_with_callout, format: :asciidoc)
      html = Coradoc.serialize(core, to: :html)

      expect(html).not_to include('&lt;1&gt;')
    end
  end

  describe 'AsciiDoc → AsciiDoc round-trip' do
    it 'preserves the marker in code and the annotation paragraph' do
      core = Coradoc.parse(adoc_with_callout, format: :asciidoc)
      out = Coradoc.serialize(core, to: :asciidoc)

      expect(out).to include("get '/hi' do <1>")
      expect(out).to include('<1> Returns hello world')
    end
  end
end
