# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Lazy do
  describe Coradoc::Lazy::DocumentWrapper do
    let(:section1) do
      Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 1,
        title: 'Section 1',
        children: []
      )
    end

    let(:section2) do
      Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 2,
        title: 'Section 2',
        children: []
      )
    end

    let(:paragraph) do
      Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: 'Test paragraph'
      )
    end

    let(:document) do
      Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [section1, paragraph, section2]
      )
    end

    let(:wrapper) { described_class.new(document) }

    describe '#initialize' do
      it 'creates wrapper with default options' do
        expect(wrapper.document).to eq(document)
      end

      it 'accepts custom batch size' do
        custom_wrapper = described_class.new(document, batch_size: 5)
        expect(custom_wrapper).to be_a(described_class)
      end

      it 'accepts cache option' do
        cached_wrapper = described_class.new(document, cache_processed: false)
        expect(cached_wrapper).to be_a(described_class)
      end
    end

    describe '#each_section' do
      it 'yields sections lazily' do
        sections = []
        wrapper.each_section { |s| sections << s }
        expect(sections).to contain_exactly(section1, section2)
      end

      it 'returns enumerator without block' do
        enum = wrapper.each_section
        expect(enum).to be_a(Enumerator)
        expect(enum.to_a).to contain_exactly(section1, section2)
      end

      it 'handles empty document' do
        empty_doc = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          children: []
        )
        empty_wrapper = described_class.new(empty_doc)
        expect(empty_wrapper.each_section.to_a).to eq([])
      end
    end

    describe '#each_child' do
      it 'yields all children' do
        children = wrapper.each_child.to_a
        expect(children).to eq([section1, paragraph, section2])
      end

      it 'returns enumerator without block' do
        enum = wrapper.each_child
        expect(enum).to be_a(Enumerator)
      end
    end

    describe '#section_at' do
      it 'returns section at index' do
        expect(wrapper.section_at(0)).to eq(section1)
        expect(wrapper.section_at(1)).to eq(section2)
      end

      it 'returns nil for out of bounds' do
        expect(wrapper.section_at(99)).to be_nil
        expect(wrapper.section_at(-1)).to be_nil
      end

      it 'handles nil index' do
        expect(wrapper.section_at(nil)).to be_nil
      end
    end

    describe '#first_sections' do
      it 'returns first N sections' do
        expect(wrapper.first_sections(1)).to eq([section1])
        expect(wrapper.first_sections(2)).to contain_exactly(section1, section2)
      end

      it 'returns all sections if N exceeds count' do
        result = wrapper.first_sections(100)
        expect(result).to contain_exactly(section1, section2)
      end
    end

    describe '#each_batch' do
      it 'yields sections in batches' do
        batches = wrapper.each_batch(1).to_a
        expect(batches).to eq([[section1], [section2]])
      end

      it 'respects batch size' do
        batches = []
        wrapper.each_batch(2) { |b| batches << b }
        expect(batches).to eq([[section1, section2]])
      end

      it 'returns enumerator without block' do
        enum = wrapper.each_batch(1)
        expect(enum).to be_a(Enumerator)
      end
    end

    describe '#section_count' do
      it 'returns section count' do
        expect(wrapper.section_count).to eq(2)
      end

      it 'returns 0 for empty document' do
        empty_doc = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          children: []
        )
        empty_wrapper = described_class.new(empty_doc)
        expect(empty_wrapper.section_count).to eq(0)
      end
    end

    describe '#each' do
      it 'aliases to each_section' do
        sections = wrapper.each.to_a
        expect(sections).to contain_exactly(section1, section2)
      end
    end
  end

  describe Coradoc::Lazy::TransformationPipeline do
    let(:source) { [1, 2, 3, 4, 5] }
    let(:pipeline) { described_class.new(source) }

    describe '#initialize' do
      it 'creates pipeline with source' do
        expect(pipeline.to_a).to eq([1, 2, 3, 4, 5])
      end
    end

    describe '#map' do
      it 'adds map transformation' do
        result = pipeline.map { |x| x * 2 }.to_a
        expect(result).to eq([2, 4, 6, 8, 10])
      end
    end

    describe '#select' do
      it 'adds filter transformation' do
        result = pipeline.select(&:even?).to_a
        expect(result).to eq([2, 4])
      end
    end

    describe '#reject' do
      it 'adds rejection transformation' do
        result = pipeline.reject(&:even?).to_a
        expect(result).to eq([1, 3, 5])
      end
    end

    describe '#flat_map' do
      it 'adds flat map transformation' do
        result = pipeline.flat_map { |x| [x, x * 2] }.to_a
        expect(result).to eq([1, 2, 2, 4, 3, 6, 4, 8, 5, 10])
      end
    end

    describe '#take' do
      it 'takes first N elements' do
        result = pipeline.take(3).to_a
        expect(result).to eq([1, 2, 3])
      end
    end

    describe '#drop' do
      it 'drops first N elements' do
        result = pipeline.drop(2).to_a
        expect(result).to eq([3, 4, 5])
      end
    end

    describe '#to_a' do
      it 'executes pipeline and returns array' do
        result = pipeline.map { |x| x * 2 }.select { |x| x > 4 }.to_a
        expect(result).to eq([6, 8, 10])
      end
    end

    describe '#to_enum' do
      it 'returns lazy enumerator' do
        enum = pipeline.map { |x| x * 2 }.to_enum
        expect(enum).to be_a(Enumerator::Lazy)
      end
    end

    describe '#each' do
      it 'iterates over results' do
        results = []
        pipeline.map { |x| x * 2 }.each { |r| results << r }
        expect(results).to eq([2, 4, 6, 8, 10])
      end

      it 'returns enumerator without block' do
        enum = pipeline.each
        expect(enum).to be_a(Enumerator::Lazy)
      end
    end

    describe '#first' do
      it 'returns first result' do
        result = pipeline.map { |x| x * 2 }.first
        expect(result).to eq(2)
      end
    end

    describe '#count' do
      it 'counts results' do
        count = pipeline.count(&:even?)
        expect(count).to eq(2)
      end
    end

    describe '#force' do
      it 'forces evaluation' do
        result = pipeline.map { |x| x * 2 }.force
        expect(result).to eq([2, 4, 6, 8, 10])
      end
    end

    describe 'chained transformations' do
      it 'supports multiple chained operations' do
        result = pipeline
                 .map { |x| x * 2 }
                 .select { |x| x > 4 }
                 .take(2)
                 .to_a
        expect(result).to eq([6, 8])
      end
    end
  end

  describe Coradoc::Lazy::ReferenceResolver do
    let(:document) { double('document') }
    let(:resolver) { described_class.new(document) }

    describe '#initialize' do
      it 'creates resolver with document' do
        expect(resolver).to be_a(described_class)
      end

      it 'accepts custom loader' do
        custom_loader = ->(ref, _doc) { "loaded: #{ref}" }
        custom_resolver = described_class.new(document, loader: custom_loader)
        expect(custom_resolver.resolve('test')).to eq('loaded: test')
      end
    end

    describe '#resolve' do
      it 'returns nil for unresolvable reference' do
        expect(resolver.resolve('unknown')).to be_nil
      end

      it 'caches resolved references' do
        allow(document).to receive(:respond_to?).and_return(false)
        # First call
        resolver.resolve('ref1')
        # Second call should use cache
        stats = resolver.cache_stats
        expect(stats[:cached_count]).to eq(1)
        expect(stats[:cached_refs]).to contain_exactly('ref1')
      end
    end

    describe '#resolvable?' do
      it 'returns false for unresolvable' do
        expect(resolver.resolvable?('unknown')).to be false
      end
    end

    describe '#clear_cache' do
      it 'clears resolved cache' do
        resolver.resolve('ref1')
        resolver.clear_cache
        stats = resolver.cache_stats
        expect(stats[:cached_count]).to eq(0)
      end
    end

    describe '#cache_stats' do
      it 'returns cache statistics' do
        resolver.resolve('ref1')
        resolver.resolve('ref2')
        stats = resolver.cache_stats
        expect(stats[:cached_count]).to eq(2)
        expect(stats[:cached_refs]).to contain_exactly('ref1', 'ref2')
      end
    end
  end

  describe Coradoc::Lazy::ChunkProcessor do
    let(:processor) { described_class.new(chunk_size: 10) }

    describe '#initialize' do
      it 'creates processor with default chunk size' do
        default_processor = described_class.new
        expect(default_processor).to be_a(described_class)
      end

      it 'accepts custom chunk size' do
        expect(processor).to be_a(described_class)
      end
    end

    describe '#process' do
      it 'processes string in chunks' do
        chunks = []
        processor.process('12345678901234567890') do |chunk, index|
          chunks << [chunk, index]
        end
        expect(chunks).to eq([
                               ['1234567890', 0],
                               ['1234567890', 1]
                             ])
      end

      it 'handles short content' do
        chunks = []
        processor.process('short') { |c, i| chunks << [c, i] }
        expect(chunks).to eq([['short', 0]])
      end

      it 'handles empty content' do
        chunks = []
        processor.process('') { |c, i| chunks << [c, i] }
        expect(chunks).to eq([])
      end

      it 'returns enumerator without block' do
        enum = processor.process('test content')
        expect(enum).to be_a(Enumerator)
      end
    end
  end

  describe 'module methods' do
    describe '.wrap' do
      it 'creates document wrapper' do
        doc = double('document')
        wrapper = described_class.wrap(doc)
        expect(wrapper).to be_a(Coradoc::Lazy::DocumentWrapper)
      end

      it 'passes options' do
        doc = double('document')
        wrapper = described_class.wrap(doc, batch_size: 5)
        expect(wrapper).to be_a(Coradoc::Lazy::DocumentWrapper)
      end
    end

    describe '.transform' do
      it 'creates transformation pipeline' do
        pipeline = described_class.transform([1, 2, 3])
        expect(pipeline).to be_a(Coradoc::Lazy::TransformationPipeline)
      end

      it 'yields pipeline for configuration' do
        result = described_class.transform([1, 2, 3]) do |p|
          p.map { |x| x * 2 }
        end.to_a
        expect(result).to eq([2, 4, 6])
      end
    end

    describe '.resolver' do
      it 'creates reference resolver' do
        doc = double('document')
        resolver = described_class.resolver(doc)
        expect(resolver).to be_a(Coradoc::Lazy::ReferenceResolver)
      end

      it 'accepts custom loader' do
        doc = double('document')
        loader = ->(ref, _) { ref.upcase }
        resolver = described_class.resolver(doc, loader: loader)
        expect(resolver.resolve('test')).to eq('TEST')
      end
    end

    describe '.each_chunk' do
      it 'processes content in chunks' do
        chunks = []
        described_class.each_chunk('1234567890123456', chunk_size: 5) do |c, i|
          chunks << [c, i]
        end
        expect(chunks).to eq([
                               ['12345', 0],
                               ['67890', 1],
                               ['12345', 2],
                               ['6', 3]
                             ])
      end

      it 'returns enumerator without block' do
        enum = described_class.each_chunk('test', chunk_size: 2)
        expect(enum).to be_a(Enumerator)
      end
    end

    describe '.lazy_enum' do
      it 'creates lazy enumerator from array' do
        enum = described_class.lazy_enum([1, 2, 3])
        expect(enum).to be_a(Enumerator::Lazy)
      end

      it 'handles non-arrays' do
        enum = described_class.lazy_enum(1..5)
        expect(enum).to be_a(Enumerator::Lazy)
      end
    end

    describe '.filter_map' do
      it 'maps and filters in single pass' do
        result = described_class.filter_map([1, 2, 3, 4, 5]) do |x|
          x * 2 if x.even?
        end.to_a
        expect(result).to eq([4, 8])
      end
    end
  end

  describe 'integration with CoreModel' do
    it 'wraps large documents efficiently' do
      # Create a document with many sections
      children = Array.new(100) do |i|
        Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          level: 1,
          title: "Section #{i}",
          children: []
        )
      end

      document = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: children
      )

      wrapper = described_class.wrap(document)

      # Test lazy processing
      first_five = wrapper.first_sections(5)
      expect(first_five.size).to eq(5)
      expect(first_five.first.title).to eq('Section 0')

      # Test batch processing
      batch_count = 0
      wrapper.each_batch(10) { |_| batch_count += 1 }
      expect(batch_count).to eq(10)
    end

    it 'transforms document sections lazily' do
      section = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 1,
        title: 'Test',
        children: []
      )

      document = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [section]
      )

      wrapper = described_class.wrap(document)
      titles = described_class.transform(wrapper.each_section)
                              .map(&:title)
                              .to_a

      expect(titles).to eq(['Test'])
    end
  end
end
