# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/markdown'
require 'tmpdir'

RSpec.describe Coradoc::Markdown::Lint do
  def lint(content)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'doc.md')
      File.write(path, content)
      Coradoc::Lint.run(path)
    end
  end

  it 'registers the markdown rules' do
    expect(Coradoc::Lint.registry.rule_ids(:markdown))
      .to contain_exactly('MD001', 'MD024')
  end

  describe 'MD001 heading levels' do
    it 'flags skipped levels' do
      expect(lint("# T\n\n## S\n\n#### D\n").map(&:rule_id)).to eq(%w[MD001])
    end

    it 'accepts single-step nesting' do
      expect(lint("# T\n\n## S\n\n### D\n")).to be_empty
    end
  end

  describe 'MD024 duplicate headings' do
    it 'flags same-level duplicates' do
      violations = lint("# S\n\ntext\n\n# S\n\nmore\n")

      expect(violations.map(&:rule_id)).to eq(%w[MD024])
      expect(violations.first.message).to include('level 1')
    end

    it 'accepts the same text at different levels' do
      expect(lint("# S\n\n## S\n")).to be_empty
    end
  end

  it 'reports clean documents as empty' do
    expect(lint("# T\n\n## S\n\ntext\n")).to be_empty
  end
end
