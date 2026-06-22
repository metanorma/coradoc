# frozen_string_literal: true

require 'spec_helper'

# Cross-format regression for BUG-deflist-backtick-stripped.md.
# Inline formatting (backtick code spans in particular) inside a
# definition list term or definition was being dropped by the
# Markdown transformer, which read `term` / `definitions` (plain
# strings) and ignored the typed inline children. The result was
# raw `<` characters in the Markdown output, which VitePress
# interprets as HTML tags and fails the build.
RSpec.describe 'Definition list inline formatting', type: :integration do
  let(:adoc) do
    "`Symbols`:: `<div class=\"Symbols\">` contents are a definition list\n"
  end

  it 'CoreModel captures typed inline children on both sides' do
    core = Coradoc.parse(adoc, format: :asciidoc)
    item = core.children.first.items.first

    expect(item.term_children.map(&:class)).to include(Coradoc::CoreModel::MonospaceElement)
    expect(item.definition_children.map(&:class)).to include(Coradoc::CoreModel::MonospaceElement)
  end

  it 'Markdown preserves backtick code spans in term and definition' do
    core = Coradoc.parse(adoc, format: :asciidoc)
    md = Coradoc.serialize(core, to: :markdown, markdown_flavor: :vitepress)

    expect(md).to eq("`Symbols`\n: `<div class=\"Symbols\">`  contents are a definition list")
  end

  it 'plain-text definition lists still serialize without children' do
    core = Coradoc.parse("Term:: plain definition\n", format: :asciidoc)
    md = Coradoc.serialize(core, to: :markdown, markdown_flavor: :vitepress)

    expect(md).to eq("Term\n: plain definition")
  end
end
