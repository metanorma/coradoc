# frozen_string_literal: true

require 'spec_helper'

# Regression for BUG-all-remaining-gaps.md. AsciiDoc → Markdown
# (VitePress flavor) conversion previously leaked bare `<` characters
# for eight construct categories, which broke VitePress's Vue template
# compiler downstream.
#
# Scope:
#   1. Literal blocks (`....`) → fenced code block (no language)
#   2. Sidebar blocks (`****`) → `:::info` container
#   3. Pass blocks (`++++`) → wrapped so raw content does not leak as
#      prose
#   4. Callouts (`<N>`) inside literal blocks → stripped, annotation
#      emitted as numbered list
#   5. Callouts (`<N>`) inside table cells → stripped from cell text
#   6. Source blocks inside sidebars → code fence preserved within
#      `:::info`
#   7. Example blocks inside open blocks → `:::details` container
#      preserved
#   8. Inline passthrough (`+++...+++`) → delimiters stripped
RSpec.describe 'AsciiDoc → Markdown conversion gaps (BUG-all-remaining-gaps)', type: :integration do
  def to_markdown(src)
    Coradoc.convert(
      src + "\n",
      from: :asciidoc, to: :markdown, markdown_flavor: :vitepress
    )
  end

  describe 'Bug 1: literal block' do
    it 'renders as a fenced code block without a language' do
      md = to_markdown(<<~ADOC)
        ....
        <clause id="test">
          <p>Content</p>
        </clause>
        ....
      ADOC
      expect(md).to include("```\n<clause id=\"test\">")
      expect(md).to include('</clause>')
    end
  end

  describe 'Bug 2: sidebar block' do
    it 'renders as a :::info container' do
      md = to_markdown(<<~ADOC)
        ****
        Text in sidebar.
        ****
      ADOC
      expect(md).to include(':::info')
      expect(md).to include('Text in sidebar.')
      expect(md).to include(':::')
      expect(md).not_to include('<div')
    end
  end

  describe 'Bug 3: pass block' do
    it 'wraps raw content so it does not leak as prose' do
      md = to_markdown(<<~ADOC)
        ++++
        <raw html/>
        ++++
      ADOC
      expect(md).to include('<raw html/>')
      expect(md).not_to include('++++')
    end
  end

  describe 'Bug 4: callouts inside literal blocks' do
    it 'strips the marker and emits annotation as numbered list' do
      md = to_markdown(<<~ADOC)
        ....
        code <1>
        ....
        <1> Annotation
      ADOC
      expect(md).to include('```')
      expect(md).not_to match(/code\s*<1>/)
      expect(md).to include('1. Annotation')
    end
  end

  describe 'Bug 5: callouts inside table cells' do
    it 'strips the marker from cell text' do
      md = to_markdown(<<~ADOC)
        |===
        | Cell text <1>
        |===

        <1> Annotation
      ADOC
      expect(md).not_to match(/Cell text\s*<1>/)
      expect(md).to include('Cell text')
    end
  end

  describe 'Bug 6: source block inside sidebar' do
    it 'preserves the code fence inside the container' do
      md = to_markdown(<<~ADOC)
        ****
        [source,ruby]
        ----
        puts 'hi'
        ----
        ****
      ADOC
      expect(md).to include(':::info')
      expect(md).to include("```ruby")
      expect(md).to include("puts 'hi'")
      expect(md).to include(':::')
    end
  end

  describe 'Bug 7: example block inside open block' do
    it 'renders as :::details container' do
      md = to_markdown(<<~ADOC)
        --
        ====
        Example text.
        ====
        --
      ADOC
      expect(md).to include(':::details')
      expect(md).to include('Example text.')
      expect(md).to include(':::')
      expect(md).not_to include('<div class="example">')
    end
  end

  describe 'Bug 8: inline passthrough' do
    it 'strips the triple-plus delimiters' do
      md = to_markdown('+++ <div class="cta">Click</div> +++')
      expect(md).not_to include('+++')
    end
  end
end
