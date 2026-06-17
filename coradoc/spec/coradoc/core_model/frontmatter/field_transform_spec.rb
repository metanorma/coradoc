# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::FrontmatterBlock::FieldTransform do
  describe 'Base' do
    it 'does not apply by default' do
      transform = described_class::Base.new
      expect(transform.applies?(direction: :to_format, format: :markdown)).to be false
    end

    it 'returns the block unchanged by default' do
      block = Coradoc::CoreModel::FrontmatterBlock.new
      transform = described_class::Base.new
      expect(transform.apply(block)).to eq(block)
    end
  end

  describe 'Registry' do
    let(:registry) { described_class::Registry.new }

    it 'starts with zero transforms' do
      expect(registry.count).to eq(0)
    end

    it 'registers a transform class' do
      klass = Class.new(described_class::Base)
      registry.register(klass)
      expect(registry.count).to eq(1)
    end

    it 'does not register the same class twice' do
      klass = Class.new(described_class::Base)
      registry.register(klass)
      registry.register(klass)
      expect(registry.count).to eq(1)
    end

    describe '#apply_all' do
      it 'returns the block unchanged when no transforms apply' do
        block = Coradoc::CoreModel::FrontmatterBlock.new
        result = registry.apply_all(block, direction: :to_format, format: :markdown)
        expect(result).to eq(block)
      end

      it 'applies matching transforms in registration order' do
        klass = Class.new(described_class::Base) do
          def applies?(direction:, format:)
            direction == :to_format && format == :markdown
          end

          def apply(block)
            new_data = (block.data || {}).except('drop_me')
            rebuild(block, data: new_data)
          end
        end
        registry.register(klass)

        block = Coradoc::CoreModel::FrontmatterBlock.new(
          data: { 'drop_me' => 'x', 'keep_me' => 'y' }
        )

        result = registry.apply_all(block, direction: :to_format, format: :markdown)
        expect(result.has_entry?('drop_me')).to be false
        expect(result.has_entry?('keep_me')).to be true
      end

      it 'skips transforms that do not apply' do
        markdown_only = Class.new(described_class::Base) do
          def applies?(direction:, format:) # rubocop:disable Lint/UnusedMethodArgument
            format == :markdown
          end

          def apply(block)
            rebuild(block, data: {})
          end
        end
        adoc_only = Class.new(described_class::Base) do
          def applies?(direction:, format:) # rubocop:disable Lint/UnusedMethodArgument
            format == :asciidoc
          end

          def apply(block)
            new_data = (block.data || {}).merge('adoc_only' => '1')
            rebuild(block, data: new_data)
          end
        end
        registry.register(markdown_only)
        registry.register(adoc_only)

        block = Coradoc::CoreModel::FrontmatterBlock.new(
          data: { 'orig' => 'v' }
        )

        result = registry.apply_all(block, direction: :to_format, format: :asciidoc)
        expect(result.has_entry?('orig')).to be true
        expect(result.has_entry?('adoc_only')).to be true
      end

      it 'does not mutate the input block' do
        klass = Class.new(described_class::Base) do
          def applies?(direction:, format:) # rubocop:disable Lint/UnusedMethodArgument
            direction == :to_format
          end

          def apply(block)
            rebuild(block, data: {})
          end
        end
        registry.register(klass)

        block = Coradoc::CoreModel::FrontmatterBlock.new(
          data: { 'x' => 'y' }
        )
        registry.apply_all(block, direction: :to_format, format: :markdown)

        expect(block.data.size).to eq(1)
      end
    end
  end
end
