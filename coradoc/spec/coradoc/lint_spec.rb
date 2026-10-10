# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Coradoc::Lint do
  def write_bad(dir)
    path = File.join(dir, 'bad.adoc')
    File.write(path, "intro\n\n== S\n\n==== Skips\n")
    path
  end

  def write_good(dir)
    path = File.join(dir, 'good.adoc')
    File.write(path, "= Title\n\n== S\n\ntext\n")
    path
  end

  it 'reports model-driven violations with rule ids' do
    Dir.mktmpdir do |dir|
      violations = described_class.run(write_bad(dir))

      ids = violations.map(&:rule_id)
      expect(ids).to include('ADOC001', 'ADOC002', 'ADOC003')
      expect(violations.first.path).to end_with('bad.adoc')
    end
  end

  it 'returns nothing for a clean document' do
    Dir.mktmpdir do |dir|
      expect(described_class.run(write_good(dir))).to be_empty
    end
  end

  it 'restricts rules with only:' do
    Dir.mktmpdir do |dir|
      violations = described_class.run(write_bad(dir), only: %w[ADOC002])

      expect(violations.map(&:rule_id)).to eq(%w[ADOC002])
    end
  end

  it 'skips rules with except:' do
    Dir.mktmpdir do |dir|
      violations = described_class.run(write_bad(dir), except: %w[ADOC003])

      expect(violations.map(&:rule_id)).not_to include('ADOC003')
    end
  end

  it 'lints a SourceGraph directly (twin integration)' do
    Dir.mktmpdir do |dir|
      graph = Coradoc::SourceGraph.build(write_bad(dir))
      violations = described_class.run(graph)

      expect(violations.map(&:rule_id)).to include('ADOC001')
    end
  end

  describe Coradoc::Lint::Violation do
    it 'formats as path:line [ID] message' do
      v = described_class.new(rule_id: 'ADOC001', path: 'a.adoc', line: 4,
                              message: 'skips', severity: :warning)

      expect(v.to_s).to eq('a.adoc:4 [ADOC001] skips')
    end

    it 'omits the line part when unknown' do
      v = described_class.new(rule_id: 'ADOC002', path: 'a.adoc', line: nil,
                              message: 'no title', severity: :warning)

      expect(v.to_s).to eq('a.adoc [ADOC002] no title')
    end
  end

  describe Coradoc::Lint::Registry do
    let(:rule_one) do
      Class.new(Coradoc::Lint::Rule) do
        rule_id 'X001'
        applies_to :testing
      end
    end

    let(:rule_two) do
      Class.new(Coradoc::Lint::Rule) do
        rule_id 'X002'
        applies_to :testing
      end
    end

    let(:anonymous) { Class.new(Coradoc::Lint::Rule) }

    def registry
      reg = described_class.new
      reg.register(rule_one)
      reg.register(rule_two)
      reg
    end

    it 'selects rules by format' do
      expect(registry.for_format(:testing).map(&:id)).to eq(%w[X001 X002])
      expect(registry.for_format(:other)).to be_empty
    end

    it 'applies only/ and except/ filters' do
      expect(registry.for_format(:testing, only: %w[X002]).map(&:id)).to eq(%w[X002])
      expect(registry.for_format(:testing, except: %w[X002]).map(&:id)).to eq(%w[X001])
    end

    it 'rejects rules without id or format' do
      expect { registry.register(anonymous) }.to raise_error(ArgumentError, /id/)
    end
  end
end
