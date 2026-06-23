# frozen_string_literal: true

require 'spec_helper'

# Regression for BUG-deflist-backtick-still-stripped.md.
#
# Commit 9e77ff7 partially fixed backtick preservation in definition
# list items, but only when the TERM had backtick formatting. When
# the term was plain text (especially with spaces), inline formatting
# in the definition was still being stripped.
#
# Root cause: the Markdown transformer used the flattened `item.definitions`
# string array, losing typed inline elements (MonospaceElement, etc.).
# Fix: thread `term_children` and `definition_children` through the
# Markdown DefinitionItem/DefinitionTerm models and render them via
# `ctx.serialize_inline_join`.
RSpec.describe 'Definition list inline formatting', type: :integration do
  let(:source) do
    <<~ADOC
      Symbols and abbreviated terms:: `<div class="Symbols">` contents
    ADOC
  end

  it 'preserves backticks in definition when term has no formatting' do
    md = Coradoc.serialize(
      Coradoc.parse(source, format: :asciidoc),
      to: :markdown, markdown_flavor: :vitepress
    )
    expect(md).to include('`<div class="Symbols">`')
    expect(md).to include('Symbols and abbreviated terms')
  end

  it 'preserves backticks in both term and definition' do
    source = "`Symbols`:: `<div class=\"Symbols\">` contents\n"
    md = Coradoc.serialize(
      Coradoc.parse(source, format: :asciidoc),
      to: :markdown, markdown_flavor: :vitepress
    )
    expect(md).to include('`Symbols`')
    expect(md).to include('`<div class="Symbols">`')
  end

  it 'preserves bold term and italic definition' do
    source = "*Bold Term*:: _italic definition_\n"
    md = Coradoc.serialize(
      Coradoc.parse(source, format: :asciidoc),
      to: :markdown, markdown_flavor: :vitepress
    )
    expect(md).to include('**Bold Term**')
    expect(md).to include('*italic definition*')
  end

  it 'renders plain text definitions unchanged' do
    source = "Term:: plain text definition\n"
    md = Coradoc.serialize(
      Coradoc.parse(source, format: :asciidoc),
      to: :markdown, markdown_flavor: :vitepress
    )
    expect(md).to include('Term')
    expect(md).to include(': plain text definition')
  end

  it 'CoreModel preserves typed definition_children' do
    core = Coradoc.parse(source, format: :asciidoc)
    item = core.children.first.items.first
    expect(item.definition_children).not_to be_empty
    expect(item.definition_children.first).to be_a(Coradoc::CoreModel::MonospaceElement)
  end
end
