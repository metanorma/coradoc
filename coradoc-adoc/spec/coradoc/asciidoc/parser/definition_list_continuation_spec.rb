# frozen_string_literal: true

require 'spec_helper'

# Regression specs for two definition-list continuation bugs:
#
# A. A definition list SPLIT when a `+`-attached block (NOTE, example,
#    …) was followed by blank lines before the next item — nothing
#    consumed the trailing empty lines, so `dlist_item.repeat` could not
#    resume. Nested `:::` values then parsed as a detached sibling list
#    and subsequent `::` attributes were absorbed into it at the wrong
#    depth. (Asciidoctor: blank lines do not end a list.)
#
# B. A `+` line directly before a nested/continuing list could not
#    attach it: the `attached` alternation only accepted admonitions,
#    paragraphs and blocks. The `+` marker dangled and the following
#    list split off. Asciidoctor treats `+` before a continuing dlist
#    run as a list-continuation marker — the items stay in the current
#    list and nest by delimiter depth — and attaches bullet/ordered
#    lists into the dd.
RSpec.describe 'AsciiDoc definition list continuation' do
  def parse_to_core(input)
    Coradoc.parse(input, format: :asciidoc)
  end

  def top_level_dlists(core)
    core.children.select { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
  end

  describe 'blank lines after a `+`-attached block' do
    it 'keeps values nested after an attached NOTE (blank line before values)' do
      core = parse_to_core(<<~ADOC)
        `:doctype:`:: type of document.
        +
        NOTE: Unlike ISO.

        `international-standard`::: International Standard
        `technical-specification`::: Technical Specification

        `:function:`:: function of document.
        `emc`::: EMC
      ADOC

      dls = top_level_dlists(core)
      expect(dls.length).to eq(1)

      items = dls.first.items
      expect(items.map(&:term)).to eq([':doctype:', ':function:'])

      doctype = items[0]
      expect(doctype.nested).to be_a(Coradoc::CoreModel::DefinitionList)
      expect(doctype.nested.items.map(&:term))
        .to eq(%w[international-standard technical-specification])
      expect(doctype.attached_children.length).to eq(1)
      expect(doctype.attached_children.first).to be_a(Coradoc::CoreModel::AnnotationBlock)

      expect(items[1].nested.items.map(&:term)).to eq(%w[emc])
    end

    it 'does not split after an attached example block followed by blank lines' do
      core = parse_to_core(<<~ADOC)
        `:a:`:: first.
        +
        [example]
        ====
        An example.
        ====

        `:b:`:: second.
      ADOC

      dls = top_level_dlists(core)
      expect(dls.length).to eq(1)
      expect(dls.first.items.map(&:term)).to eq([':a:', ':b:'])
    end

    it 'still ends the list at a paragraph (no over-merging)' do
      core = parse_to_core(<<~ADOC)
        `:a:`:: first.

        A paragraph between the lists.

        `:b:`:: second.
      ADOC

      dls = top_level_dlists(core)
      expect(dls.length).to eq(2)
      expect(dls[0].items.map(&:term)).to eq([':a:'])
      expect(dls[1].items.map(&:term)).to eq([':b:'])
    end
  end

  describe '`+` before a continuing definition list run' do
    it 'keeps the run in the current list (nests by delimiter depth)' do
      core = parse_to_core(<<~ADOC)
        `:document-scheme:`:: The document scheme.
        +
        Accepted values:
        +
        `ieee-sa-2021`::: (default)

        `:program:`:: Program under which a white paper was authored.
      ADOC

      dls = top_level_dlists(core)
      expect(dls.length).to eq(1)

      items = dls.first.items
      expect(items.map(&:term)).to eq([':document-scheme:', ':program:'])
      scheme = items[0]
      expect(scheme.nested).to be_a(Coradoc::CoreModel::DefinitionList)
      expect(scheme.nested.items.map(&:term)).to eq(%w[ieee-sa-2021])
    end

    it 'does not swallow the following top-level attribute into the values' do
      core = parse_to_core(<<~ADOC)
        `:a:`:: text.
        +
        `x`::: X

        `:b:`:: second.
      ADOC

      dls = top_level_dlists(core)
      expect(dls.length).to eq(1)
      expect(dls.first.items.map(&:term)).to eq([':a:', ':b:'])
      expect(dls.first.items[0].nested.items.map(&:term)).to eq(%w[x])
      expect(dls.first.items[1].nested).to be_nil
    end
  end

  describe '`+` before a bullet list' do
    it 'attaches the bullet list to the dd' do
      core = parse_to_core(<<~ADOC)
        `ieee-sa-2021`::: (default)
        +
        * A "Word usage" subclause will be supplied.
        * The "Participants" clause will be generated.

        `legacy`::: fallback
      ADOC

      dls = top_level_dlists(core)
      expect(dls.length).to eq(1)
      items = dls.first.items
      expect(items.map(&:term)).to eq(%w[ieee-sa-2021 legacy])
      expect(items[0].attached_children.length).to eq(1)
    end
  end

  describe 'comment lines inside a definition list' do
    it 'skips `//` comment lines between items' do
      core = parse_to_core(<<~ADOC)
        `:a:`:: first.

        // `:annextitle:`:: Shorthand for x.

        `:b:`:: second.
      ADOC

      dls = top_level_dlists(core)
      expect(dls.length).to eq(1)
      expect(dls.first.items.map(&:term)).to eq([':a:', ':b:'])
    end
  end
end
