# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'

RSpec.describe Coradoc::Pipeline do
  describe '.build' do
    it 'yields a fresh DocumentElement' do
      doc = described_class.build do |d|
        d.title = 'Hello'
      end
      expect(doc).to be_a(Coradoc::CoreModel::DocumentElement)
      expect(doc.title).to eq('Hello')
    end
  end

  describe '.parse / .serialize round-trip' do
    it 'routes through the registered format' do
      adoc = "= Title\n\nbody"
      core = described_class.parse(adoc, format: :asciidoc)
      expect(core).to be_a(Coradoc::CoreModel::Base)

      out = described_class.serialize(core, to: :asciidoc)
      expect(out).to include('Title')
      expect(out).to include('body')
    end
  end

  describe '.convert' do
    it 'composes parse + serialize' do
      adoc = "= Hello\n\nWorld"
      out = described_class.convert(adoc, from: :asciidoc, to: :asciidoc)
      expect(out).to include('Hello')
    end
  end

  describe '.to_core' do
    it 'returns CoreModel inputs unchanged' do
      doc = Coradoc::CoreModel::DocumentElement.new
      expect(described_class.to_core(doc)).to be(doc)
    end
  end
end
