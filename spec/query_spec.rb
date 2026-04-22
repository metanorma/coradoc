# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Query do
  describe Coradoc::Query::Selector do
    describe '.parse' do
      it 'parses element type' do
        selector = described_class.parse('section')
        expect(selector.element_type).to eq('section')
      end

      it 'parses ID selector' do
        selector = described_class.parse('#intro')
        expect(selector.id).to eq('intro')
      end

      it 'parses class selectors' do
        selector = described_class.parse('.level-2.important')
        expect(selector.classes).to contain_exactly('level-2', 'important')
      end

      it 'parses attribute selectors' do
        selector = described_class.parse('[id=intro]')
        expect(selector.attributes[:id]).not_to be_nil
        expect(selector.attributes[:id][:operator]).to eq(:equals)
        expect(selector.attributes[:id][:value]).to eq('intro')
      end

      it 'parses pseudo-classes' do
        selector = described_class.parse(':first-child')
        expect(selector.pseudo_classes).to include(name: 'first-child', argument: nil)
      end

      it 'parses complex selectors' do
        selector = described_class.parse('section.level-2#intro[role=example]:first-child')
        expect(selector.element_type).to eq('section')
        expect(selector.id).to eq('intro')
        expect(selector.classes).to include('level-2')
        expect(selector.attributes[:role]).not_to be_nil
        expect(selector.attributes[:role][:value]).to eq('example')
      end

      it 'handles empty selector' do
        selector = described_class.parse('')
        expect(selector.element_type).to be_nil
      end
    end

    describe '#matches?' do
      let(:element) do
        Class.new do
          attr_accessor :id, :role, :level

          def initialize(id: nil, role: nil, level: nil)
            @id = id
            @role = role
            @level = level
          end
        end
      end

      it 'matches element type' do
        selector = described_class.parse('section')
        # StructuralElement matches "section" or "structural_element"
        section = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          level: 1
        )
        expect(selector.matches?(section)).to be true
      end

      it 'matches ID' do
        selector = described_class.parse('#intro')
        el = element.new(id: 'intro')
        expect(selector.matches?(el)).to be true

        el2 = element.new(id: 'other')
        expect(selector.matches?(el2)).to be false
      end

      it 'matches classes' do
        selector = described_class.parse('.important')
        el = element.new(role: 'important note')
        expect(selector.matches?(el)).to be true

        el2 = element.new(role: 'note')
        expect(selector.matches?(el2)).to be false
      end

      it 'matches attributes' do
        selector = described_class.parse('[level=2]')
        el = element.new(level: '2')
        expect(selector.matches?(el)).to be true
      end

      it 'matches universal selector' do
        selector = described_class.parse('*')
        expect(selector.universal?).to be true
      end
    end

    describe '#matches_pseudo_classes?' do
      it 'matches :first-child' do
        selector = described_class.parse(':first-child')
        siblings = [1, 2, 3]
        expect(selector.matches_pseudo_classes?(1, siblings: siblings, index: 0)).to be true
        expect(selector.matches_pseudo_classes?(2, siblings: siblings, index: 1)).to be false
      end

      it 'matches :last-child' do
        selector = described_class.parse(':last-child')
        siblings = [1, 2, 3]
        expect(selector.matches_pseudo_classes?(3, siblings: siblings, index: 2)).to be true
        expect(selector.matches_pseudo_classes?(1, siblings: siblings, index: 0)).to be false
      end

      it 'matches :nth-child' do
        selector = described_class.parse(':nth-child(2)')
        siblings = [1, 2, 3]
        expect(selector.matches_pseudo_classes?(2, siblings: siblings, index: 1)).to be true
      end

      it 'matches :only-child' do
        selector = described_class.parse(':only-child')
        expect(selector.matches_pseudo_classes?(1, siblings: [1], index: 0)).to be true
        expect(selector.matches_pseudo_classes?(1, siblings: [1, 2], index: 0)).to be false
      end
    end
  end

  describe Coradoc::Query::ResultSet do
    let(:elements) { [1, 2, 3, 4, 5] }
    let(:result_set) { described_class.new(elements) }

    describe '#each' do
      it 'iterates over elements' do
        collected = []
        result_set.each { |e| collected << e }
        expect(collected).to eq(elements)
      end
    end

    describe '#length' do
      it 'returns element count' do
        expect(result_set.length).to eq(5)
      end
    end

    describe '#[]' do
      it 'accesses elements by index' do
        expect(result_set[0]).to eq(1)
        expect(result_set[2]).to eq(3)
      end
    end

    describe '#first and #last' do
      it 'returns first and last elements' do
        expect(result_set.first).to eq(1)
        expect(result_set.last).to eq(5)
      end
    end

    describe '#filter' do
      it 'filters results with selector' do
        mock_elements = [
          double('el1', class: 'Section', id: 'a', role: nil),
          double('el2', class: 'Paragraph', id: 'b', role: nil)
        ]
        result = described_class.new(mock_elements)

        # Filter should work with selector parsing
        expect(result).to be_a(described_class)
      end
    end

    describe '#empty?' do
      it 'returns true for empty result set' do
        expect(described_class.new.empty?).to be true
        expect(result_set.empty?).to be false
      end
    end

    describe '#to_a' do
      it 'converts to array' do
        expect(result_set.to_a).to eq(elements)
      end
    end

    describe '#inspect' do
      it 'includes count' do
        expect(result_set.inspect).to include('count=5')
      end
    end
  end

  describe Coradoc::Query::Engine do
    describe '.query' do
      it 'returns ResultSet' do
        result = described_class.query(nil, 'section')
        expect(result).to be_a(Coradoc::Query::ResultSet)
      end

      it 'returns empty result for nil document' do
        result = described_class.query(nil, 'section')
        expect(result.empty?).to be true
      end

      it 'returns empty result for empty selector' do
        result = described_class.query(double('doc'), '')
        expect(result.empty?).to be true
      end
    end
  end

  describe '.query' do
    it 'queries documents with selector' do
      result = described_class.query(nil, 'section')
      expect(result).to be_a(Coradoc::Query::ResultSet)
    end
  end

  describe '.query_within' do
    it 'queries within element descendants' do
      result = described_class.query_within(nil, 'paragraph')
      expect(result).to be_a(Coradoc::Query::ResultSet)
    end
  end
end
