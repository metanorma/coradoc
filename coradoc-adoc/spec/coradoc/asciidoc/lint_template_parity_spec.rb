# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require_relative '../../support/legacy_lint_rules'

# #309: the template-bound ADOC001/ADOC005 must report exactly what the
# retired hand-written rules reported.
RSpec.describe 'AsciiDoc lint templates vs retired rules' do
  fixtures = {
    'clean' => "= T\n\n== S\n\ntext\n\n=== D\n\ntext\n",
    'skip' => "intro\n\n== S\n\n==== Skips\n\ntext\n",
    'nested skip' => "= T\n\n== A\n\n=== B\n\n===== C\n\ntext\n",
    'duplicate ids' => "[#dup]\n== One\n\ntext\n\n[#dup]\n== Two\n\ntext\n\n[#dup]\n=== Three\n\ntext\n",
    'both' => "[#x]\n== A\n\n[#x]\n==== B\n\ntext\n"
  }

  let(:legacy) do
    Coradoc::Lint::Registry.new.register(LegacyLint::AdocHeadingLevels)
                           .register(LegacyLint::AdocDuplicateIds)
  end
  let(:templated) do
    Coradoc::Lint::Registry.new.tap do |registry|
      Coradoc::AsciiDoc::Lint::Registrations::RULES.each { |rule| registry.register(rule) }
    end
  end

  def findings(registry, content)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'doc.adoc')
      File.write(path, content)
      Coradoc::Lint::Runner.new(registry: registry).run(path).map { |v| v.to_h.merge(path: 'doc.adoc') }
    end
  end

  fixtures.each do |name, content|
    it "reports identical findings for #{name}" do
      expect(findings(templated, content)).to eq(findings(legacy, content))
    end
  end

  it 'exercises every ported rule over the fixtures' do
    ids = fixtures.values.flat_map { |content| findings(legacy, content) }.map { |f| f[:rule_id] }

    expect(ids.tally).to include('ADOC001' => be >= 2, 'ADOC005' => be >= 2)
  end

  it 'binds the same rule ids and format as the retired rules' do
    expect(templated.rule_ids(:asciidoc)).to match_array(legacy.rule_ids(:asciidoc))
  end
end
