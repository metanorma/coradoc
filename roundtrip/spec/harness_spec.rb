# frozen_string_literal: true

require 'tmpdir'
require_relative 'spec_helper'

# The harness must itself be trusted: each property it checks is shown to
# fail on an injected defect and to pass on a clean round trip.
RSpec.describe Coradoc::Roundtrip do
  let(:checker) { Coradoc::Roundtrip::Checker.new }
  let(:kase) { Coradoc::Roundtrip::Case.new('markdown:t', :markdown, "# T\n\nhello\n", 't') }
  let(:core) { Coradoc::Markdown.parse_to_core("# T\n\nhello\n") }

  describe Coradoc::Roundtrip::Checker do
    it 'accepts a construct that round-trips' do
      expect(checker.call(kase)).to be_nil
    end

    it 'reports a parse crash with the stage' do
      allow(Coradoc).to receive(:parse).and_raise(ArgumentError, 'boom')

      expect(checker.call(kase)).to have_attributes(stage: :parse, message: 'ArgumentError: boom')
    end

    it 'locates a model change by path' do
      outputs = ["# T\n\nhello\n", "# T\n\nCHANGED\n"]
      allow(Coradoc).to receive(:serialize).and_return(outputs.first)
      parsed = false
      allow(Coradoc).to receive(:parse).and_wrap_original do |original, text, **opts|
        source = parsed ? outputs.last : text
        parsed = true
        original.call(source, **opts)
      end

      failure = checker.call(kase)

      expect(failure).to have_attributes(stage: :model)
      expect(failure.path).to start_with('$.')
    end

    it 'reports a non-fixed-point serialization with line and both passes' do
      calls = 0
      allow(Coradoc).to receive(:parse).and_return(core)
      allow(Coradoc).to receive(:serialize) { "pass #{calls += 1}\n" }

      failure = checker.call(kase)

      expect(failure).to have_attributes(stage: :canonical, path: 'line 1')
      expect(failure.snippet).to include('pass 1').and include('pass 2')
    end

    it 'turns a hang into a timeout failure' do
      stub_const('Coradoc::Roundtrip::Checker::TIMEOUT', 0.05)
      allow(Coradoc).to receive(:parse) { sleep 1 }

      expect(checker.call(kase)).to have_attributes(stage: :timeout)
    end
  end

  describe Coradoc::Roundtrip::Projection do
    it 'finds the first differing path and ignores source_line' do
      left = { 'a' => [{ 'b' => 1 }, { 'b' => 2 }] }
      right = { 'a' => [{ 'b' => 1 }, { 'b' => 3 }] }

      expect(described_class.first_difference(left, right)).to eq(['$.a[1].b', 2, 3])
    end

    it 'drops positional attributes from the projection' do
      one = Coradoc::CoreModel::Block.new(content: 'x', source_line: 1)
      two = Coradoc::CoreModel::Block.new(content: 'x', source_line: 9)

      expect(described_class.of(one)).to eq(described_class.of(two))
    end
  end

  describe Coradoc::Roundtrip::Corpus do
    it 'restricts to one format' do
      expect(described_class.cases(format: :markdown).map(&:format).uniq).to eq([:markdown])
    end

    it 'includes generated edge cases for both formats' do
      ids = described_class.cases.map(&:id)

      expect(ids).to include('asciidoc:edge/empty', 'markdown:edge/empty')
    end

    it 'adds an external corpus by extension' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'a.adoc'), "= A\n")
        File.write(File.join(dir, 'b.md'), "# B\n")
        File.write(File.join(dir, 'c.txt'), 'ignored')

        ids = described_class.cases(extra: dir).map(&:id)

        expect(ids).to include('asciidoc:a.adoc', 'markdown:b.md')
        expect(ids).not_to include('c.txt')
      end
    end
  end
end
