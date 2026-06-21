# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc callout markers' do
  def parse_to_core(adoc)
    Coradoc.parse(adoc, format: :asciidoc)
  end

  describe 'AsciiDoc → CoreModel' do
    it 'attaches a single callout annotation to a SourceBlock' do
      adoc = <<~ADOC
        [source,ruby]
        ----
        get '/hi' do <1>
        ----
        <1> Returns hello world
      ADOC

      core = parse_to_core(adoc)

      expect(core.children.size).to eq(1)
      src = core.children.first
      expect(src).to be_a(Coradoc::CoreModel::SourceBlock)
      expect(src.content).to eq("get '/hi' do <1>")
      expect(src.callouts.size).to eq(1)
      callout = src.callouts.first
      expect(callout).to be_a(Coradoc::CoreModel::Callout)
      expect(callout.index).to eq(1)
      expect(callout.content).to eq('Returns hello world')
    end

    it 'attaches multiple callouts from consecutive annotation lines' do
      adoc = <<~ADOC
        [source,ruby]
        ----
        get '/hi' do <1>
        puts "hello" <2>
        ----
        <1> Returns hello world
        <2> Prints greeting
      ADOC

      core = parse_to_core(adoc)

      src = core.children.first
      expect(src.callouts.size).to eq(2)
      expect(src.callouts.map(&:index)).to eq([1, 2])
      expect(src.callouts.map(&:content)).to eq(['Returns hello world', 'Prints greeting'])
    end

    it 'attaches callouts separated by blank lines' do
      adoc = <<~ADOC
        [source,ruby]
        ----
        get '/hi' do <1>
        ----

        <1> First

        <2> Second
      ADOC

      core = parse_to_core(adoc)

      src = core.children.first
      expect(src.callouts.map(&:index)).to eq([1, 2])
    end

    it 'leaves lone annotation paragraphs alone when no verbatim block precedes' do
      core = parse_to_core("<1> orphan annotation\n")

      expect(core.children.size).to eq(1)
      expect(core.children.first).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(core.children.first.callouts).to be_empty
    end

    it 'works inside sections' do
      adoc = <<~ADOC
        == Section

        [source,ruby]
        ----
        foo <1>
        ----
        <1> bar
      ADOC

      core = parse_to_core(adoc)
      section = core.children.first
      expect(section).to be_a(Coradoc::CoreModel::SectionElement)
      src = section.children.first
      expect(src).to be_a(Coradoc::CoreModel::SourceBlock)
      expect(src.callouts.first.content).to eq('bar')
    end

    it 'leaves literal <N> code alone when no annotation follows' do
      adoc = <<~ADOC
        [source,ruby]
        ----
        x = 1 if y < 1
        ----
      ADOC

      core = parse_to_core(adoc)
      src = core.children.first
      expect(src.callouts).to be_empty
      expect(src.content).to include('y < 1')
    end
  end

  describe 'CoreModel → AsciiDoc round-trip' do
    it 'preserves callout markers in code and re-emits annotation paragraphs' do
      adoc = <<~ADOC
        [source,ruby]
        ----
        get '/hi' do <1>
        ----
        <1> Returns hello world
      ADOC

      core = parse_to_core(adoc)
      out = Coradoc.serialize(core, to: :asciidoc)

      expect(out).to include("get '/hi' do <1>")
      expect(out).to include('<1> Returns hello world')
    end
  end
end
