# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Nested list re-nesting (same-type depth markers)' do
  def roundtrip(adoc)
    Coradoc.convert(adoc, from: :asciidoc, to: :asciidoc).strip
  end

  it 're-nests a depth-2 unordered list' do
    expect(roundtrip("* a\n** b\n")).to eq("* a\n** b")
  end

  it 're-nests a depth-2 ordered list' do
    expect(roundtrip(". a\n.. b\n")).to eq(". a\n.. b")
  end

  it 're-nests three levels' do
    expect(roundtrip("* a\n** b\n*** c\n")).to eq("* a\n** b\n*** c")
  end

  it 'keeps a sibling after the nested list' do
    expect(roundtrip("* a\n** b\n* c\n")).to eq("* a\n** b\n* c")
  end

  it 'parses the nested list into the CoreModel nested_list slot' do
    core = Coradoc.parse("* a\n** b\n", format: :asciidoc)
    list = core.children.first
    item = list.items.first
    expect(item.nested_list).to be_a(Coradoc::CoreModel::ListBlock)
    expect(item.nested_list.items.first.content).to eq('b')
  end
end
