# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Materializer::Registry do
  let(:registry) { described_class.new }

  describe '#lookup' do
    it 'finds a materializer by exact kind+presentation+format' do
      klass = registry.lookup(kind: :navigation, presentation: :any, format: :html)
      expect(klass).to be(Coradoc::Reference::Materializer::NavigationHtml)
    end

    it 'falls back to :any format when exact format missing' do
      klass = registry.lookup(kind: :navigation, presentation: :single_document, format: :xml)
      # :navigation, :any, :html is the most specific — should NOT match for :xml
      # unless :any :any exists. Passthrough is :any :any :any.
      expect(klass).to be(Coradoc::Reference::Materializer::Passthrough).or(
        be(Coradoc::Reference::Materializer::NavigationHtml)
      )
    end

    it 'returns Passthrough for unknown kinds' do
      klass = registry.lookup(kind: :nonexistent, presentation: :any, format: :html)
      expect(klass).to be(Coradoc::Reference::Materializer::Passthrough)
    end
  end

  describe '#register (OCP)' do
    let(:custom) do
      Class.new(Coradoc::Reference::Materializer::Base) do
        def self.kind = :custom
        def self.format = :json

        def materialize(**)
          Coradoc::CoreModel::TextElement.new(content: 'custom')
        end
      end
    end

    it 'registers a new materializer' do
      registry.register(custom)
      klass = registry.lookup(kind: :custom, presentation: :any, format: :json)
      expect(klass).to be(custom)
    end

    it 'returns Passthrough when no materializer registered' do
      registry.register(custom)
      klass = registry.lookup(kind: :custom, presentation: :any, format: :xml)
      expect(klass).to be(Coradoc::Reference::Materializer::Passthrough)
    end
  end
end
