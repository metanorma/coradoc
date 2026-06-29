# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# AsciiDoc's typographic quote syntax (`` "` `` / `` `" `` / `` '` `` /
# `` `' ``) substitutes straight ASCII quotes with curly Unicode quotes.
# Single-line marks (italic, bold) inside curly quotes are recognised
# correctly. Multi-line unconstrained marks (italic __ / bold **) span
# line breaks inside curly quotes — the parser's mark content
# excludes newlines by default, so relaxing that exclusion makes
# multi-line marks work the way Asciidoctor does.
#
# Coverage below locks in:
#   * Each of the four patterns emits the correct Unicode char.
#   * Inner text is NOT wrapped in a spurious MonospaceElement.
#   * Single-line italic / bold inside quotes work.
#   * Multi-line italic / bold inside quotes work (TODO.bugs/15B).
#   * Source whitespace is preserved exactly — no synthesised
#     double-spaces around the quote (TODO.bugs/15A).
#   * Plain monospace (`code`) still works when not preceded by a
#     quote char.
#   * Unconstrained marks outside quote context still work.
RSpec.describe 'Typographic quote substitution', :asciidoc do
  def first_paragraph_children(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children.first.children
  end

  def text_only(children)
    children.flat_map do |c|
      c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : c.content.to_s
    end.join
  end

  describe 'curly double quotes' do
    let(:children) { first_paragraph_children('He said "`hello world`" to me.') }

    it 'emits U+201C for the opener' do
      expect(children.map { |c| c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil })
        .to include('“')
    end

    it 'emits U+201D for the closer' do
      expect(children.map { |c| c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil })
        .to include('”')
    end

    it 'does not wrap the inner text in a MonospaceElement' do
      expect(children.none?(Coradoc::CoreModel::MonospaceElement)).to be(true)
    end
  end

  describe 'curly single quotes' do
    let(:children) { first_paragraph_children("She replied '`hi there`'.") }

    it 'emits U+2018 for the opener' do
      expect(children.map { |c| c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil })
        .to include('‘')
    end

    it 'emits U+2019 for the closer' do
      expect(children.map { |c| c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil })
        .to include('’')
    end
  end

  describe 'source whitespace preserved (TODO.bugs/15A regression guard)' do
    # The straight `"` chars in the source are PART of the typographic
    # pattern (the open pattern is `"` + `` ` ``, the close is `` ` `` + `"`)
    # and get consumed/replaced by the curly chars. The expected joined
    # text therefore contains only the curly quotes, with the source's
    # surrounding ASCII spaces preserved exactly.
    it 'preserves single spaces around quoted text without synthesising extras' do
      children = first_paragraph_children('He said "`hello world`" to me.')
      joined = text_only(children)
      expect(joined).to eq("He said “hello world” to me.")
    end

    it 'preserves leading space after the closer' do
      children = first_paragraph_children('He said "`hello`" to me.')
      joined = text_only(children)
      expect(joined).to eq("He said “hello” to me.")
    end

    it 'does not synthesise extra spaces between adjacent text and quote tokens' do
      children = first_paragraph_children('a "`x`" b')
      texts = children.map do |c|
        c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : c.content.to_s
      end
      expect(texts).to eq(['a ', '“', 'x', '”', ' b'])
    end
  end

  describe 'multi-line marks inside curly quotes (TODO.bugs/15B)' do
    it 'recognises __italic__ spanning a line break' do
      children = first_paragraph_children("\"`__Setting\nstandards__`\"")
      italic = children.find { |c| c.is_a?(Coradoc::CoreModel::ItalicElement) }
      expect(italic).not_to be_nil
      expect(italic.content).to include("Setting\nstandards")
    end

    it 'recognises **bold** spanning a line break' do
      children = first_paragraph_children("\"`**Setting\nstandards**`\"")
      bold = children.find { |c| c.is_a?(Coradoc::CoreModel::BoldElement) }
      expect(bold).not_to be_nil
      expect(bold.content).to include("Setting\nstandards")
    end

    it 'does not leak raw __ markers in multi-line italic output' do
      children = first_paragraph_children("\"`__Setting\nstandards__`\"")
      joined = text_only(children)
      expect(joined).not_to include('__')
    end

    it 'does not leak raw ** markers in multi-line bold output' do
      children = first_paragraph_children("\"`**Setting\nstandards**`\"")
      joined = text_only(children)
      expect(joined).not_to include('**')
    end
  end

  describe 'inline marks inside curly quotes (single-line, regression)' do
    it 'recognises __italic__ as ItalicElement' do
      children = first_paragraph_children('"`__Setting__`"')
      italic = children.find { |c| c.is_a?(Coradoc::CoreModel::ItalicElement) }
      expect(italic).not_to be_nil
    end

    it 'recognises **bold** as BoldElement' do
      children = first_paragraph_children('"`**critical**`"')
      bold = children.find { |c| c.is_a?(Coradoc::CoreModel::BoldElement) }
      expect(bold).not_to be_nil
    end

    it 'recognises _constrained italic_ as ItalicElement' do
      children = first_paragraph_children('"`_Setting_`"')
      italic = children.find { |c| c.is_a?(Coradoc::CoreModel::ItalicElement) }
      expect(italic).not_to be_nil
    end

    it 'recognises *constrained bold* as BoldElement' do
      children = first_paragraph_children('"`*Setting*`"')
      bold = children.find { |c| c.is_a?(Coradoc::CoreModel::BoldElement) }
      expect(bold).not_to be_nil
    end
  end

  describe 'plain monospace still works' do
    it 'wraps plain `code` in a MonospaceElement' do
      children = first_paragraph_children('Type `code` here.')
      mono = children.find { |c| c.is_a?(Coradoc::CoreModel::MonospaceElement) }
      expect(mono).not_to be_nil
      expect(mono.content).to include('code')
    end
  end

  describe 'unconstrained marks still work' do
    it '**bold** produces BoldElement' do
      children = first_paragraph_children('This is **bold** text.')
      bold = children.find { |c| c.is_a?(Coradoc::CoreModel::BoldElement) }
      expect(bold.content).to include('bold')
    end

    it '__italic__ produces ItalicElement' do
      children = first_paragraph_children('This is __italic__ text.')
      italic = children.find { |c| c.is_a?(Coradoc::CoreModel::ItalicElement) }
      expect(italic.content).to include('italic')
    end

    it '``code`` produces MonospaceElement' do
      children = first_paragraph_children('This is ``code`` text.')
      mono = children.find { |c| c.is_a?(Coradoc::CoreModel::MonospaceElement) }
      expect(mono.content).to include('code')
    end

    it '__multi-line italic__ outside quotes produces ItalicElement spanning newlines' do
      children = first_paragraph_children("__Setting\nstandards__")
      italic = children.find { |c| c.is_a?(Coradoc::CoreModel::ItalicElement) }
      expect(italic).not_to be_nil
      expect(italic.content).to include("Setting\nstandards")
    end
  end
end
