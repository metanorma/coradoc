# frozen_string_literal: true

require 'spec_helper'

# Regression for BUG-final-5-remaining.md. Five remaining AsciiDoc →
# Markdown (VitePress flavor) gaps that broke VitePress's Vue template
# compiler downstream.
#
# Scope:
#   1. Backtick code spans inside example/sidebar blocks must survive —
#      previously the typed-block transformer flattened lines to plain
#      text via extract_text_content, dropping the inline formatting.
#   2. Pass blocks must not emit kramdown's `{::nomarkdown}` extension
#      (unsupported by VitePress). Emit as an HTML comment so the raw
#      content is preserved but never parsed as HTML.
#   3. Inline passthrough (`+++raw+++`) must not leak raw HTML into
#      Markdown text. HTML-escape the content.
#   4. Callout annotation paragraphs after non-verbatim blocks (e.g.
#      Tables) must convert to a numbered list, not stay as `<N>` text.
#   5. Cross-references inside example blocks must convert to Markdown
#      links (fixed alongside Bug 1 by populating ParagraphBlock children).
RSpec.describe 'AsciiDoc → Markdown final 5 conversion gaps (BUG-final-5-remaining)', type: :integration do
  def to_markdown(src)
    Coradoc.convert(
      src + "\n",
      from: :asciidoc, to: :markdown, markdown_flavor: :vitepress
    )
  end

  describe 'Bug 1: backtick code span inside example block' do
    it 'preserves backticks around inline HTML' do
      md = to_markdown(<<~ADOC)
        ====
        Text with `<div class="test">` here.
        ====
      ADOC
      expect(md).to include('`<div class="test">`')
      expect(md).not_to match(/Text\s+<div class="test">\s+here/)
    end
  end

  describe 'Bug 1b: backtick code span inside sidebar block' do
    it 'preserves backticks around inline HTML' do
      md = to_markdown(<<~ADOC)
        ****
        Text with `<code>` here.
        ****
      ADOC
      expect(md).to include('`<code>`')
      expect(md).not_to match(/Text\s+<code>\s+here/)
    end
  end

  describe 'Bug 2: pass block' do
    it 'emits an HTML comment instead of kramdown {::nomarkdown}' do
      md = to_markdown(<<~ADOC)
        ++++
        <raw html/>
        ++++
      ADOC
      expect(md).not_to include('{::nomarkdown}')
      expect(md).to include('<!--')
      expect(md).to include('-->')
      expect(md).to include('<raw html/>')
    end
  end

  describe 'Bug 3: inline passthrough' do
    it 'HTML-escapes the passthrough content' do
      md = to_markdown('+++ <div class="cta">button</div> +++')
      expect(md).not_to include('<div')
      expect(md).to include('&lt;div')
    end
  end

  describe 'Bug 4: callout annotation after table' do
    it 'converts the annotation paragraph to a numbered list' do
      md = to_markdown(<<~ADOC)
        |===
        | Cell text <1>
        |===

        <1> This is an annotation
      ADOC
      expect(md).to include('1. This is an annotation')
      expect(md).not_to match(/<1>/)
    end
  end

  describe 'Bug 5: cross-reference inside example block' do
    it 'converts the xref to a Markdown link' do
      md = to_markdown(<<~ADOC)
        ====
        See <<id,clause "123">> for details.
        ====
      ADOC
      expect(md).to include('](#id)')
      expect(md).not_to include('<<')
    end
  end
end
