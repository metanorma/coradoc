# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Coradoc::AsciiDoc::Lint do
  def lint(content)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'doc.adoc')
      File.write(path, content)
      Coradoc::Lint.run(path)
    end
  end

  it 'registers the four v1 rules' do
    expect(Coradoc::Lint.registry.rule_ids(:asciidoc))
      .to contain_exactly('ADOC001', 'ADOC002', 'ADOC003', 'ADOC005')
  end

  describe 'ADOC001 heading levels' do
    it 'flags skipped levels' do
      expect(lint("= T\n\n== A\n\n==== Deep\n\ntext\n").map(&:rule_id))
        .to eq(%w[ADOC001])
    end

    it 'accepts single-step nesting' do
      expect(lint("= T\n\n== A\n\ntext\n\n=== B\n\ntext\n")).to be_empty
    end
  end

  describe 'ADOC002 document title' do
    it 'flags a missing level-0 title' do
      expect(lint("== A\n\ntext\n").map(&:rule_id)).to eq(%w[ADOC002])
    end

    it 'accepts a titled document' do
      expect(lint("= T\n\n== A\n\ntext\n")).to be_empty
    end
  end

  describe 'ADOC003 empty sections' do
    it 'flags sections without content or subsections' do
      expect(lint("= T\n\n== Empty\n\n== Full\n\ntext\n").map(&:rule_id))
        .to eq(%w[ADOC003])
    end

    it 'accepts sections with subsections' do
      expect(lint("= T\n\n== Parent\n\n=== Kid\n\ntext\n")).to be_empty
    end
  end

  describe 'ADOC005 duplicate ids' do
    it 'flags repeated anchors' do
      violations = lint("= T\n\n[[dup]]\n== A\n\ntext\n\n[[dup]]\n== B\n\ntext\n")

      expect(violations.map(&:rule_id)).to eq(%w[ADOC005])
      expect(violations.first.message).to include('"dup"')
    end

    it 'accepts distinct anchors' do
      expect(lint("= T\n\n[[a]]\n== A\n\ntext\n\n[[b]]\n== B\n\ntext\n")).to be_empty
    end
  end
end
