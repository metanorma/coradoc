# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Hooks do
  after do
    described_class.clear_all
  end

  describe '.register' do
    it 'registers a hook callback' do
      hook_id = described_class.register(:before_parse) { |content| content }
      expect(hook_id).to be_a(String)
    end

    it 'accepts a custom name' do
      hook_id = described_class.register(:before_parse, name: 'my_hook') { |c| c }
      expect(hook_id).to eq('my_hook')
    end

    it 'accepts a priority' do
      described_class.register(:before_parse, priority: 50) { |c| "#{c}1" }
      described_class.register(:before_parse, priority: 100) { |c| "#{c}2" }
      hooks = described_class.list(:before_parse)
      expect(hooks[0][:priority]).to eq(50)
      expect(hooks[1][:priority]).to eq(100)
    end

    it 'raises for invalid hook point' do
      expect do
        described_class.register(:invalid_hook) { |c| c }
      end.to raise_error(ArgumentError, /Unknown hook point/)
    end

    it 'raises when block is missing' do
      expect do
        described_class.register(:before_parse)
      end.to raise_error(ArgumentError, /Block required/)
    end
  end

  describe '.remove' do
    it 'removes a registered hook' do
      hook_id = described_class.register(:before_parse) { |c| c }
      result = described_class.remove(:before_parse, hook_id)
      expect(result).to be true
      expect(described_class.registered?(:before_parse)).to be false
    end

    it 'returns false for non-existent hook' do
      result = described_class.remove(:before_parse, 'non_existent')
      expect(result).to be false
    end
  end

  describe '.clear' do
    it 'clears all hooks for a hook point' do
      described_class.register(:before_parse) { |c| c }
      described_class.register(:before_parse) { |c| c }
      removed = described_class.clear(:before_parse)
      expect(removed).to eq(2)
      expect(described_class.registered?(:before_parse)).to be false
    end
  end

  describe '.clear_all' do
    it 'clears all hooks from all hook points' do
      described_class.register(:before_parse) { |c| c }
      described_class.register(:after_parse) { |m| m }
      total = described_class.clear_all
      expect(total).to eq(2)
      expect(described_class.list).to be_empty
    end
  end

  describe '.registered?' do
    it 'returns true when hooks exist' do
      described_class.register(:before_parse) { |c| c }
      expect(described_class.registered?(:before_parse)).to be true
    end

    it 'returns false when no hooks exist' do
      expect(described_class.registered?(:before_parse)).to be false
    end
  end

  describe '.list' do
    it 'lists hooks for a specific hook point' do
      described_class.register(:before_parse, name: 'hook1') { |c| c }
      described_class.register(:before_parse, name: 'hook2') { |c| c }
      hooks = described_class.list(:before_parse)
      expect(hooks.size).to eq(2)
      expect(hooks.map { |h| h[:id] }).to contain_exactly('hook1', 'hook2')
    end

    it 'lists all hooks when no hook point specified' do
      described_class.register(:before_parse, name: 'hook1') { |c| c }
      described_class.register(:after_parse, name: 'hook2') { |m| m }
      hooks = described_class.list
      expect(hooks.size).to eq(2)
    end
  end

  describe '.invoke' do
    it 'invokes hooks in priority order' do
      results = []
      described_class.register(:before_parse, priority: 100) do |c|
        results << 2
        c
      end
      described_class.register(:before_parse, priority: 50) do |c|
        results << 1
        c
      end

      described_class.invoke(:before_parse, 'test')
      expect(results).to eq([1, 2])
    end

    it 'passes result through the chain' do
      described_class.register(:before_parse) { |c| "#{c}1" }
      described_class.register(:before_parse) { |c| "#{c}2" }

      result = described_class.invoke(:before_parse, 'test')
      expect(result).to eq('test12')
    end

    it 'returns original value when no hooks registered' do
      result = described_class.invoke(:before_parse, 'test')
      expect(result).to eq('test')
    end

    it 'passes keyword arguments to hooks' do
      received = nil
      described_class.register(:before_parse) do |c, **kwargs|
        received = kwargs
        c
      end

      described_class.invoke(:before_parse, 'test', format: :asciidoc)
      expect(received).to eq({ format: :asciidoc })
    end
  end

  describe '.with_hooks' do
    it 'executes block and invokes hooks' do
      described_class.register(:before_parse, &:upcase)

      result = described_class.with_hooks(:before_parse, 'test') do |content|
        "#{content}_processed"
      end

      expect(result).to eq('TEST_processed')
    end

    it 'invokes after_* hooks automatically' do
      described_class.register(:after_parse) { |m| "#{m}_finalized" }

      result = described_class.with_hooks(:before_parse, 'test') do |content|
        "#{content}_processed"
      end

      expect(result).to eq('test_processed_finalized')
    end
  end

  describe 'error handling' do
    it 'handles hook failures gracefully' do
      described_class.register(:before_parse) { |_c| raise 'Hook error' }
      described_class.register(:before_parse) { |c| "#{c}_ok" }

      # Should not raise, just skip the failing hook
      result = described_class.invoke(:before_parse, 'test')
      expect(result).to eq('test_ok')
    end

    it 'invokes on_error hooks when errors occur' do
      error_received = nil
      described_class.register(:on_error) do |error, _context|
        error_received = error
        'fallback'
      end

      result = described_class.with_hooks(:before_parse, 'test') do
        raise 'Test error'
      end

      expect(error_received).to be_a(RuntimeError)
      expect(result).to eq('fallback')
    end

    it 're-raises error if no on_error hook handles it' do
      expect do
        described_class.with_hooks(:before_parse, 'test') do
          raise 'Unhandled error'
        end
      end.to raise_error('Unhandled error')
    end
  end

  describe '.documentation' do
    it 'returns documentation for a specific hook point' do
      doc = described_class.documentation(:before_parse)
      expect(doc).to include('before parsing')
    end

    it 'returns all documentation without argument' do
      docs = described_class.documentation
      expect(docs).to be_a(Hash)
      expect(docs.keys).to include(:before_parse, :after_parse, :on_error)
    end
  end

  describe 'hook points' do
    it 'defines all expected hook points' do
      expected_points = %i[
        before_parse after_parse
        before_transform after_transform
        before_serialize after_serialize
        on_error
      ]
      expect(Coradoc::Hooks::HOOK_POINTS.keys).to eq(expected_points)
    end
  end
end
