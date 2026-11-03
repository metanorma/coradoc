# frozen_string_literal: true

require 'spec_helper'

# The parity checks compare against the hand-written classes, which are not
# loaded when CORADOC_MARKDOWN_GENERATED=1 replaces them.
RSpec.describe Coradoc::Markdown::Schema do
  let(:markdown) { Coradoc::Markdown }
  let(:schema_names) { described_class::Definition.read(described_class.files).map(&:name) }

  before do
    skip 'hand-written classes are replaced by generated ones' if ENV['CORADOC_MARKDOWN_GENERATED'] == '1'

    described_class.load_generated unless Coradoc::Markdown.const_defined?(:Generated, false)
  end

  describe 'IR parity with the hand-written models' do
    it 'has no difference in attributes, types, collections or defaults' do
      diff = described_class::Parity.diff(expected: markdown, actual: markdown::Generated, names: schema_names)

      expect(diff).to eq([])
    end

    it 'declares every hand-written model class' do
      live = markdown.constants.map { |c| markdown.const_get(c) }
                     .select { |k| k.is_a?(Class) && k < markdown::Base }
                     .map { |k| k.name.split('::').last }

      expect(schema_names).to match_array(live)
    end

    it 'reports a drifted attribute' do
      drifted = Class.new(markdown::Base) { attribute :level, :string }
      reference = Class.new(markdown::Base) { attribute :level, :integer, default: 1 }
      expected = Module.new.tap { |m| m.const_set(:Heading, reference) }
      actual = Module.new.tap { |m| m.const_set(:Heading, drifted) }

      diff = described_class::Parity.diff(expected: expected, actual: actual, names: ['Heading'], except: [])

      expect(diff).to include('Heading.level: type "Integer" != "String"',
                              'Heading.level: default 1 != :none')
    end

    it 'documents the one accepted difference' do
      raw = described_class::Parity.diff(expected: markdown, actual: markdown::Generated,
                                         names: schema_names, except: [])

      expect(raw).to eq(described_class::Parity::KNOWN_DIFFERENCES)
    end
  end

  describe 'generated classes' do
    let(:generated) { markdown::Generated }

    it 'honors a false default, which the lutaml renderer drops' do
      expect(generated::Math.new.inline).to be(false)
    end

    it 'inherits the hand-written Base' do
      expect(generated::Heading.superclass).to eq(markdown::Base)
    end
  end

  describe 'behavior mixins on generated classes' do
    let(:generated) { markdown::Generated }

    it 'adds instance methods' do
      expect(generated::Heading.new(text: 'Hello World!').heading_id).to eq('hello-world')
    end

    it 'overrides an attribute setter and reaches the generated one through super' do
      expect(generated::Admonition.new(admonition_type: 'NOTE').admonition_type).to eq('note')
    end

    it 'adds class methods' do
      expect(generated::Extension.toc('levels' => '2').options.map(&:name)).to eq(['levels'])
    end

    it 'shares each behavior module with the hand-written class' do
      expect(markdown::Heading.ancestors).to include(markdown::Behaviors::Heading)
      expect(generated::Heading.ancestors).to include(markdown::Behaviors::Heading)
    end
  end
end
