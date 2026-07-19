# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Materializer::Registry do
  # Spec-local materializers — real classes per project spec rules.
  let(:navigation_html) do
    Class.new(Coradoc::Reference::Materializer::Base) do
      def self.kind
        :navigation
      end

      def self.presentation
        :any
      end

      def self.format
        :html
      end
    end
  end

  let(:navigation_split_html) do
    Class.new(Coradoc::Reference::Materializer::Base) do
      def self.kind
        :navigation
      end

      def self.presentation
        :split_pages
      end

      def self.format
        :html
      end
    end
  end

  let(:navigation_any) do
    Class.new(Coradoc::Reference::Materializer::Base) do
      def self.kind
        :navigation
      end

      def self.presentation
        :any
      end

      def self.format
        :any
      end
    end
  end

  describe '#lookup fallback chain' do
    it 'finds the exact [kind, presentation, format] match first' do
      registry = described_class.new
      registry.register(navigation_html)
      registry.register(navigation_split_html)
      klass = registry.lookup(kind: :navigation, presentation: :split_pages, format: :html)
      expect(klass).to be(navigation_split_html)
    end

    it 'falls back to :any presentation' do
      registry = described_class.new
      registry.register(navigation_html)
      klass = registry.lookup(kind: :navigation, presentation: :single_document, format: :html)
      expect(klass).to be(navigation_html)
    end

    it 'falls back to :any format' do
      registry = described_class.new
      registry.register(navigation_any)
      klass = registry.lookup(kind: :navigation, presentation: :any, format: :docx)
      expect(klass).to be(navigation_any)
    end

    it 'prefers a concrete presentation over :any when both exist' do
      registry = described_class.new
      registry.register(navigation_html)
      registry.register(navigation_split_html)
      klass = registry.lookup(kind: :navigation, presentation: :custom_hierarchy, format: :html)
      expect(klass).to be(navigation_html)
    end

    it 'falls back to Passthrough when no materializer matches' do
      registry = described_class.new
      klass = registry.lookup(kind: :image_ref, presentation: :any, format: :html)
      expect(klass).to be(Coradoc::Reference::Materializer::Passthrough)
    end
  end

  describe '#register (OCP timing)' do
    it 'never clobbers a registration made before builtins were loaded' do
      registry = described_class.new
      registry.register(navigation_html)
      # Force lazy builtin registration via an unrelated lookup
      registry.lookup(kind: :citation, presentation: :any, format: :any)
      klass = registry.lookup(kind: :navigation, presentation: :any, format: :html)
      expect(klass).to be(navigation_html)
    end
  end

  describe '.register_global (format gems)' do
    let(:docx_materializer) do
      Class.new(Coradoc::Reference::Materializer::Base) do
        def self.kind
          :navigation
        end

        def self.presentation
          :any
        end

        def self.format
          :docx
        end
      end
    end

    after { described_class.reset_globals! }

    it 'makes externally registered materializers available to every new instance' do
      described_class.register_global(docx_materializer)
      registry = described_class.new
      klass = registry.lookup(kind: :navigation, presentation: :any, format: :docx)
      expect(klass).to be(docx_materializer)
    end

    it 'registers the same class only once' do
      described_class.register_global(docx_materializer)
      described_class.register_global(docx_materializer)
      expect(described_class.global_registrations.count(docx_materializer)).to eq(1)
    end
  end
end
