# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::FrontmatterBlock::SchemaResolver do
  describe 'ValidationError' do
    it 'is a keyword-init Struct with field and message' do
      err = described_class::ValidationError.new(field: 'title', message: 'missing')
      expect(err.field).to eq('title')
      expect(err.message).to eq('missing')
    end
  end

  describe 'Base' do
    it 'returns no errors by default' do
      resolver = described_class::Base.new
      expect(resolver.validate(Coradoc::CoreModel::FrontmatterBlock.new)).to eq([])
    end
  end

  describe 'Registry' do
    let(:registry) { described_class::Registry.new }

    it 'starts empty' do
      expect(registry.registered?('https://x.com/s.json')).to be false
    end

    it 'registers and looks up a resolver class' do
      klass = Class.new(described_class::Base)
      registry.register('https://x.com/s.json', klass)

      expect(registry.registered?('https://x.com/s.json')).to be true
      expect(registry.lookup('https://x.com/s.json')).to eq(klass)
    end

    describe '#validate' do
      it 'returns empty array when block has no schema' do
        block = Coradoc::CoreModel::FrontmatterBlock.new
        expect(registry.validate(block)).to eq([])
      end

      it 'returns empty array when no resolver is registered' do
        block = Coradoc::CoreModel::FrontmatterBlock.new(schema: 'https://nope.com/s.json')
        expect(registry.validate(block)).to eq([])
      end

      it 'delegates to the registered resolver' do
        resolver_class = Class.new(described_class::Base) do
          def validate(_block)
            [Coradoc::CoreModel::FrontmatterBlock::SchemaResolver::ValidationError.new(
              field: 'title', message: 'required'
            )]
          end
        end
        registry.register('https://x.com/s.json', resolver_class)

        block = Coradoc::CoreModel::FrontmatterBlock.new(schema: 'https://x.com/s.json')
        errors = registry.validate(block)

        expect(errors.size).to eq(1)
        expect(errors.first.field).to eq('title')
        expect(errors.first.message).to eq('required')
      end
    end
  end
end
