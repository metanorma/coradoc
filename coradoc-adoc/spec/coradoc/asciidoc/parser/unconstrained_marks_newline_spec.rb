# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# Commit ee92b2b unified the four unconstrained inline marks
# (`**`, `__`, `##`, ` `` `) so they all allow newlines inside their
# content. Previously `highlight_unconstrained` (`##…##`) excluded
# newlines while the other three allowed them — an inconsistency
# flagged in Bug 15B's fix scope but not previously spec'd.
#
# These specs lock in the unified behaviour.
RSpec.describe 'Unconstrained inline marks spanning newlines', :asciidoc do
  def first_paragraph(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children.first
  end

  {
    Coradoc::CoreModel::BoldElement => '**',
    Coradoc::CoreModel::ItalicElement => '__',
    Coradoc::CoreModel::HighlightElement => '##',
    Coradoc::CoreModel::MonospaceElement => '``'
  }.each_pair do |klass, marker|
    describe "#{klass.name.split('::').last} via #{marker}…#{marker}" do
      let(:adoc) { "#{marker}multi\nline#{marker}" }
      let(:mark) { first_paragraph(adoc).children.find { |c| c.is_a?(klass) } }

      it 'produces the mark element' do
        expect(mark).to be_a(klass)
      end

      it 'preserves the newline in the mark content' do
        expect(mark.content).to eq("multi\nline")
      end
    end
  end

  describe 'paragraph breaks still terminate constrained marks' do
    # The constrained builder's `reject_paragraph_break: true` is only
    # applied to bold_constrained (Asciidoctor's behaviour). The other
    # three constrained marks reject paragraph breaks via the default
    # `[^<marker>\n]` content rule, which excludes `\n`.
    it 'bold_constrained does not span paragraph breaks' do
      adoc = "*foo\n\nbar*"
      para = first_paragraph(adoc)
      bolds = para.children.select { |c| c.is_a?(Coradoc::CoreModel::BoldElement) }
      expect(bolds).to be_empty
    end
  end
end
