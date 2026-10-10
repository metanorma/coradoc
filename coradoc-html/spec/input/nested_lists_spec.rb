# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Nested lists in html→adoc (#68 territory)' do
  def conv(html)
    Coradoc.convert(html, from: :html, to: :asciidoc).strip
  end

  it 'keeps a nested unordered list inside an ordered item' do
    expect(conv('<ol><li>a<ul><li>b</li></ul></li></ol>')).to eq(". a\n* b")
  end

  it 'keeps a nested ordered list inside an unordered item' do
    expect(conv('<ul><li>a<ol><li>b</li></ol></li></ul>')).to eq("* a\n. b")
  end

  it 'deepens same-type nesting' do
    expect(conv('<ol><li>a<ol><li>b</li></ol></li></ol>')).to eq(". a\n.. b")
    expect(conv('<ul><li>a<ul><li>b</li></ul></li></ul>')).to eq("* a\n** b")
  end

  it 'keeps three levels of nesting' do
    html = '<ul><li>a<ul><li>b<ul><li>c</li></ul></li></ul></li></ul>'
    expect(conv(html)).to eq("* a\n** b\n*** c")
  end

  it 'keeps siblings after a nested list' do
    html = '<ul><li>a<ul><li>b</li></ul></li><li>c</li></ul>'
    expect(conv(html)).to eq("* a\n** b\n* c")
  end
end
