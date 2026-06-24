# frozen_string_literal: true

require 'spec_helper'

# Locks in the HasChildren predicate so downstream dispatch can rely on
# `is_a?(HasChildren)` instead of enumerating subclasses (OCP).
RSpec.describe Coradoc::CoreModel::HasChildren do
  # Classes that carry a +children+ collection and should satisfy
  # HasChildren — either directly (StructuralElement) or transitively
  # via ChildrenContent (the rest).
  include_examples = [
    [Coradoc::CoreModel::Block, true],
    [Coradoc::CoreModel::ParagraphBlock, true],   # via Block
    [Coradoc::CoreModel::AnnotationBlock, true],  # via Block
    [Coradoc::CoreModel::InlineElement, true],
    [Coradoc::CoreModel::BoldElement, true],      # via InlineElement
    [Coradoc::CoreModel::TableCell, true],
    [Coradoc::CoreModel::ListItem, true],
    [Coradoc::CoreModel::StructuralElement, true],
    [Coradoc::CoreModel::DocumentElement, true],  # via StructuralElement
    [Coradoc::CoreModel::SectionElement, true]    # via StructuralElement
  ].freeze

  # Classes that should NOT satisfy HasChildren — they carry their own
  # named collection (e.g. Table#rows) or are leaf nodes with no
  # children.
  exclude_examples = [
    [Coradoc::CoreModel::TextContent, false],
    [Coradoc::CoreModel::Table, false],            # has :rows, not :children
    [Coradoc::CoreModel::Image, false],
    [Coradoc::CoreModel::Metadata, false],
    [Coradoc::CoreModel::ElementAttribute, false]
  ].freeze

  include_examples.each do |klass, expected|
    it "#{klass} includes HasChildren (#{expected})" do
      instance = begin
        klass.new
      rescue StandardError
        klass.new(children: [])
      end
      expect(instance.is_a?(Coradoc::CoreModel::HasChildren)).to eq(expected)
      expect(instance.has_children?).to eq(expected)
    end
  end

  exclude_examples.each do |klass, _expected|
    it "#{klass} does NOT satisfy HasChildren" do
      instance = klass.new
      expect(instance.is_a?(Coradoc::CoreModel::HasChildren)).to be(false)
    end
  end
end
