# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Lint::Template do
  let(:node_class) { Struct.new(:level, :name, :kids, keyword_init: true) }

  def node(level, name, *kids)
    node_class.new(level: level, name: name, kids: kids)
  end

  def run_rule(rule, doc)
    rule.new.check(doc, 'x').map(&:message)
  end

  def tree_rule(**extra)
    described_class.bind(:monotonic, id: 'T001', format: :test,
                                     roots: :itself.to_proc, children: :kids.to_proc,
                                     level: :level.to_proc, label: :name.to_proc, **extra)
  end

  describe ':monotonic' do
    it 'flags a child more than one level below its parent (tree)' do
      doc = [node(1, 'a', node(3, 'deep'))]

      expect(run_rule(tree_rule, doc)).to eq(['heading level skips from 1 to 3: deep'])
    end

    it 'treats top-level nodes as children of level 0' do
      expect(run_rule(tree_rule, [node(2, 'late')]))
        .to eq(['heading level skips from 0 to 2: late'])
    end

    it 'skips nodes without a level and keeps the enclosing level' do
      doc = [node(1, 'a', node(nil, 'x', node(2, 'ok')))]

      expect(run_rule(tree_rule, doc)).to be_empty
    end

    it 'compares against the previous node in :sequence order' do
      rule = described_class.bind(:monotonic, id: 'T002', format: :test, order: :sequence,
                                              roots: :itself.to_proc, level: :level.to_proc,
                                              label: :name.to_proc)
      doc = [node(1, 'a'), node(2, 'b'), node(4, 'c'), node(2, 'd')]

      expect(run_rule(rule, doc)).to eq(['heading level skips from 2 to 4: c'])
    end

    it 'accepts a message override' do
      rule = tree_rule(message: ->(from, to, label) { "#{label}: #{from}->#{to}" })

      expect(run_rule(rule, [node(3, 'z')])).to eq(['z: 0->3'])
    end

    it 'rejects an unknown order' do
      expect { tree_rule(order: :spiral) }.to raise_error(ArgumentError, /order/)
    end
  end

  describe ':unique' do
    let(:rule) do
      described_class.bind(:unique, id: 'T003', format: :test,
                                    roots: :itself.to_proc, children: :kids.to_proc,
                                    key: :name.to_proc,
                                    message: ->(key, count) { "#{key} x#{count}" })
    end

    it 'reports keys used more than once, including nested ones, in first-seen order' do
      doc = [node(1, 'b', node(2, 'a')), node(1, 'a'), node(1, 'b'), node(1, 'a')]

      expect(run_rule(rule, doc)).to eq(['b x2', 'a x3'])
    end

    it 'ignores nil keys' do
      expect(run_rule(rule, [node(1, nil), node(1, nil)])).to be_empty
    end
  end

  describe ':present' do
    let(:rule) do
      described_class.bind(:present, id: 'T004', format: :test,
                                     subjects: :itself.to_proc,
                                     present: ->(n) { !n.name.to_s.strip.empty? },
                                     message: ->(n) { "blank at level #{n.level}" })
    end

    it 'reports every subject failing the presence test' do
      doc = [node(1, 'ok'), node(2, ' '), node(3, nil)]

      expect(run_rule(rule, doc)).to eq(['blank at level 2', 'blank at level 3'])
    end
  end

  describe '.bind' do
    it 'returns a Rule subclass carrying id and format' do
      rule = tree_rule

      expect(rule.superclass).to eq(Coradoc::Lint::Rule)
      expect([rule.id, rule.format]).to eq(['T001', :test])
    end

    it 'raises on an unknown operator' do
      expect { described_class.bind(:nope, id: 'X', format: :test) }
        .to raise_error(ArgumentError, /unknown template operator/)
    end

    it 'raises on a missing ref' do
      expect { described_class.bind(:unique, id: 'X', format: :test, roots: :itself.to_proc) }
        .to raise_error(ArgumentError, /missing refs.*key/)
    end

    it 'raises on an unknown ref' do
      expect { tree_rule(bogus: 1) }.to raise_error(ArgumentError, /unknown refs/)
    end

    it 'raises on a non-callable ref' do
      expect { tree_rule(level: 3) }.to raise_error(ArgumentError, /must be callable/)
    end

    it 'produces violations carrying the rule id and path' do
      violation = tree_rule.new.check([node(2, 'late')], 'doc.x').first

      expect([violation.rule_id, violation.path]).to eq(%w[T001 doc.x])
    end
  end

  describe '.register' do
    it 'adds the bound rule to the given registry' do
      registry = Coradoc::Lint::Registry.new
      rule = described_class.register(:present, registry: registry, id: 'T005', format: :test,
                                                subjects: :itself.to_proc, present: ->(_) { true },
                                                message: ->(_) { '' })

      expect(registry.for_format(:test)).to eq([rule])
    end
  end
end
