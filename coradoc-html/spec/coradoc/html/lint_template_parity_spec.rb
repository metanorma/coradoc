# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require_relative '../../support/legacy_lint_rules'

# #309: the template-bound HTML001/HTML002 must report exactly what the
# retired hand-written rules reported.
RSpec.describe 'HTML lint templates vs retired rules' do
  fixtures = {
    'clean' => '<h1>A</h1><h2>B</h2><img src="a.png" alt="a">',
    'skip' => '<h1>A</h1><h3>B</h3><h6>C</h6>',
    'missing alt' => '<img src="x.png"><img src="y.png" alt="ok">',
    'blank alt' => '<img src="x.png" alt="  ">',
    'both' => '<h2>A</h2><h4>B</h4><img src="z.png">'
  }

  let(:legacy) do
    Coradoc::Lint::Registry.new.register(LegacyLint::HtmlHeadingLevels)
                           .register(LegacyLint::HtmlImageAlt)
  end
  let(:templated) do
    Coradoc::Lint::Registry.new.tap do |registry|
      Coradoc::Html::Lint::Registrations::RULES.each { |rule| registry.register(rule) }
    end
  end

  def findings(registry, content)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'doc.html')
      File.write(path, content)
      Coradoc::Lint::Runner.new(registry: registry).run(path).map { |v| v.to_h.merge(path: 'doc.html') }
    end
  end

  fixtures.each do |name, content|
    it "reports identical findings for #{name}" do
      expect(findings(templated, content)).to eq(findings(legacy, content))
    end
  end

  it 'exercises every ported rule over the fixtures' do
    ids = fixtures.values.flat_map { |content| findings(legacy, content) }.map { |f| f[:rule_id] }

    expect(ids.tally).to include('HTML001' => be >= 3, 'HTML002' => be >= 2)
  end

  it 'binds the same rule ids and format as the retired rules' do
    expect(templated.rule_ids(:html)).to match_array(legacy.rule_ids(:html))
  end
end
