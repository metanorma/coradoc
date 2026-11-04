# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/markdown'
require 'tmpdir'
require_relative '../../support/legacy_lint_rules'

# #309: the template-bound MD001/MD024 must report exactly what the
# retired hand-written rules reported.
RSpec.describe 'Markdown lint templates vs retired rules' do
  fixtures = {
    'clean' => "# T\n\n## S\n\ntext\n",
    'skip' => "# T\n\n## S\n\n#### D\n",
    'multiple skips' => "# T\n\n### A\n\n##### B\n\n## C\n",
    'duplicates' => "# S\n\ntext\n\n# S\n\nmore\n\n# S\n",
    'same text different levels' => "# S\n\n## S\n",
    'both' => "# S\n\n#### S\n\n# S\n"
  }

  let(:legacy) do
    Coradoc::Lint::Registry.new.register(LegacyLint::MdHeadingLevels)
                           .register(LegacyLint::MdDuplicateHeadings)
  end
  let(:templated) do
    Coradoc::Lint::Registry.new.tap do |registry|
      Coradoc::Markdown::Lint::Registrations::RULES.each { |rule| registry.register(rule) }
    end
  end

  def findings(registry, content)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'doc.md')
      File.write(path, content)
      Coradoc::Lint::Runner.new(registry: registry).run(path).map { |v| v.to_h.merge(path: 'doc.md') }
    end
  end

  fixtures.each do |name, content|
    it "reports identical findings for #{name}" do
      expect(findings(templated, content)).to eq(findings(legacy, content))
    end
  end

  it 'exercises every ported rule over the fixtures' do
    ids = fixtures.values.flat_map { |content| findings(legacy, content) }.map { |f| f[:rule_id] }

    expect(ids.tally).to include('MD001' => be >= 3, 'MD024' => be >= 2)
  end

  it 'binds the same rule ids and format as the retired rules' do
    expect(templated.rule_ids(:markdown)).to match_array(legacy.rule_ids(:markdown))
  end
end
