# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/transform/helpers'

RSpec.describe Coradoc::Transform::Helpers do
  # Create a test class that includes the helpers
  let(:helper_class) do
    Class.new do
      include Coradoc::Transform::Helpers

      # Simple transform for testing
      def transform(element)
        "transformed: #{element}"
      end
    end
  end

  let(:helper) { helper_class.new }

  describe '#extract_text' do
    it 'returns empty string for nil' do
      expect(helper.extract_text(nil)).to eq('')
    end

    it 'returns content for objects with content method' do
      obj = double('object', content: 'text content')

      expect(helper.extract_text(obj)).to eq('text content')
    end

    it 'returns text for objects with text method' do
      obj = double('object', text: 'text value')

      expect(helper.extract_text(obj)).to eq('text value')
    end

    it 'returns to_s for strings' do
      expect(helper.extract_text('simple string')).to eq('simple string')
    end

    it 'prefers content over text method' do
      obj = double('object', content: 'from content', text: 'from text')

      expect(helper.extract_text(obj)).to eq('from content')
    end

    it 'returns empty string for objects without content or text' do
      obj = Object.new

      expect(helper.extract_text(obj)).to eq('')
    end
  end

  describe '#safe_string' do
    it 'returns empty string for nil' do
      expect(helper.safe_string(nil)).to eq('')
    end

    it 'returns content for objects with content method' do
      obj = double('object', content: 'value')

      expect(helper.safe_string(obj)).to eq('value')
    end

    it 'returns text for objects with text method' do
      obj = double('object', text: 'text value')

      expect(helper.safe_string(obj)).to eq('text value')
    end

    it 'returns to_s for other objects' do
      expect(helper.safe_string(123)).to eq('123')
    end
  end

  describe '#safe_array' do
    it 'returns empty array for nil' do
      expect(helper.safe_array(nil)).to eq([])
    end

    it 'returns the array for arrays' do
      arr = [1, 2, 3]

      expect(helper.safe_array(arr)).to eq(arr)
    end

    it 'wraps single object in array' do
      expect(helper.safe_array('single')).to eq(['single'])
    end

    it 'converts objects with to_a' do
      obj = double('object', to_a: [1, 2])

      expect(helper.safe_array(obj)).to eq([1, 2])
    end
  end

  describe '#transform_collection' do
    it 'returns empty array for nil' do
      expect(helper.transform_collection(nil)).to eq([])
    end

    it 'transforms each element' do
      result = helper.transform_collection([1, 2, 3])

      expect(result).to eq(['transformed: 1', 'transformed: 2', 'transformed: 3'])
    end

    it 'filters nils by default' do
      allow(helper).to receive(:transform).and_return(nil, 'value', nil)

      result = helper.transform_collection([1, 2, 3])

      expect(result).to eq(['value'])
    end

    it 'keeps nils when filter_nils is false' do
      allow(helper).to receive(:transform).and_return(nil, 'value', nil)

      result = helper.transform_collection([1, 2, 3], filter_nils: false)

      expect(result).to eq([nil, 'value', nil])
    end
  end

  describe '#safe_attribute' do
    it 'returns default for nil object' do
      expect(helper.safe_attribute(nil, :name, default: 'default')).to eq('default')
    end

    it 'gets attribute value with method call' do
      obj = double('object', name: 'value')

      expect(helper.safe_attribute(obj, :name)).to eq('value')
    end

    it 'gets attribute value with hash access' do
      obj = { name: 'hash value' }

      expect(helper.safe_attribute(obj, :name)).to eq('hash value')
    end

    it 'returns default for missing attribute' do
      obj = double('object')

      expect(helper.safe_attribute(obj, :missing, default: 'default')).to eq('default')
    end

    it 'returns default for nil attribute value' do
      obj = double('object', name: nil)

      expect(helper.safe_attribute(obj, :name, default: 'default')).to eq('default')
    end
  end

  describe '#core_model?' do
    it 'returns false for nil' do
      expect(helper.core_model?(nil)).to be false
    end

    it 'returns false for non-CoreModel objects' do
      expect(helper.core_model?('string')).to be false
      expect(helper.core_model?(123)).to be false
    end

    context 'with CoreModel classes' do
      before do
        # Define a test CoreModel class
        module Coradoc
          module CoreModel
            class TestBase; end
          end
        end
      end

      it 'returns true for CoreModel objects' do
        obj = Coradoc::CoreModel::TestBase.new

        expect(helper.core_model?(obj)).to be true
      end
    end
  end

  describe '#inline_element?' do
    it 'returns false for nil' do
      expect(helper.inline_element?(nil)).to be false
    end

    it 'returns false for non-inline elements' do
      expect(helper.inline_element?('text')).to be false
    end
  end

  describe '#block_element?' do
    it 'returns false for nil' do
      expect(helper.block_element?(nil)).to be false
    end

    it 'returns false for non-block elements' do
      expect(helper.block_element?('text')).to be false
    end
  end

  describe '#structural_element?' do
    it 'returns false for nil' do
      expect(helper.structural_element?(nil)).to be false
    end

    it 'returns false for non-structural elements' do
      expect(helper.structural_element?('text')).to be false
    end
  end

  describe '#element_type' do
    it 'returns nil for nil element' do
      expect(helper.element_type(nil)).to be_nil
    end

    it 'returns element_type attribute if present' do
      obj = double('object', element_type: 'paragraph')

      expect(helper.element_type(obj)).to eq('paragraph')
    end

    it 'returns nil if element_type is nil' do
      obj = double('object', element_type: nil)

      expect(helper.element_type(obj)).to be_nil
    end
  end

  describe '#class_to_element_type' do
    it 'converts CamelCase to snake_case' do
      # Use a class from core_model if available, otherwise use String
      test_class = if defined?(Coradoc::CoreModel::StructuralElement)
                     Coradoc::CoreModel::StructuralElement
                   else
                     String
                   end

      result = helper.class_to_element_type(test_class)
      expect(result).to match(/^(structural_element|string)$/)
    end

    it 'handles single word class names' do
      expect(helper.class_to_element_type(String)).to eq('string')
    end

    it 'handles nested class names' do
      module TestModule
        class TestClass; end
      end

      expect(helper.class_to_element_type(TestModule::TestClass)).to eq('test_class')
    end
  end

  describe '#deep_transform' do
    it 'returns nil for nil' do
      expect(helper.deep_transform(nil)).to be_nil
    end

    it 'transforms arrays recursively' do
      result = helper.deep_transform([1, 2, 3])

      expect(result).to eq(['transformed: 1', 'transformed: 2', 'transformed: 3'])
    end

    it 'transforms hash values recursively' do
      result = helper.deep_transform({ a: 1, b: 2 })

      expect(result).to eq({ a: 'transformed: 1', b: 'transformed: 2' })
    end

    it 'transforms single objects' do
      expect(helper.deep_transform('item')).to eq('transformed: item')
    end
  end

  describe '#merge_options' do
    it 'merges options with defaults' do
      defaults = { a: 1, b: 2 }
      options = { b: 3, c: 4 }

      result = helper.merge_options(options, defaults)

      expect(result).to eq({ a: 1, b: 3, c: 4 })
    end

    it 'handles nil options' do
      defaults = { a: 1, b: 2 }

      result = helper.merge_options(nil, defaults)

      expect(result).to eq(defaults)
    end
  end

  describe '#extract_id' do
    it 'returns nil for nil element' do
      expect(helper.extract_id(nil)).to be_nil
    end

    it 'extracts id from object with id method' do
      obj = double('object', id: 'my-id')

      expect(helper.extract_id(obj)).to eq('my-id')
    end

    it 'extracts id from hash' do
      obj = { id: 'hash-id' }

      expect(helper.extract_id(obj)).to eq('hash-id')
    end

    it 'returns nil for empty string id' do
      obj = double('object', id: '')

      expect(helper.extract_id(obj)).to be_nil
    end

    it 'returns nil for missing id' do
      obj = double('object')

      expect(helper.extract_id(obj)).to be_nil
    end
  end

  describe '#extract_level' do
    it 'returns default for nil element' do
      expect(helper.extract_level(nil, default: 2)).to eq(2)
    end

    it 'extracts level from object with level method' do
      obj = double('object', level: 3)

      expect(helper.extract_level(obj)).to eq(3)
    end

    it 'extracts level from hash' do
      obj = { level: 4 }

      expect(helper.extract_level(obj)).to eq(4)
    end

    it 'returns default for missing level' do
      obj = double('object')

      expect(helper.extract_level(obj, default: 5)).to eq(5)
    end

    it 'converts level to integer' do
      obj = double('object', level: '2')

      expect(helper.extract_level(obj)).to eq(2)
    end
  end

  describe '#extract_language' do
    it 'returns nil for nil element' do
      expect(helper.extract_language(nil)).to be_nil
    end

    it 'extracts language from object with language method' do
      obj = double('object', language: 'ruby')

      expect(helper.extract_language(obj)).to eq('ruby')
    end

    it 'extracts language from object with lang method' do
      obj = double('object', lang: 'python')

      expect(helper.extract_language(obj)).to eq('python')
    end

    it 'extracts language from hash with language key' do
      obj = { language: 'javascript' }

      expect(helper.extract_language(obj)).to eq('javascript')
    end

    it 'extracts language from hash with lang key' do
      obj = { lang: 'go' }

      expect(helper.extract_language(obj)).to eq('go')
    end

    it 'returns nil for empty string language' do
      obj = double('object', language: '')

      expect(helper.extract_language(obj)).to be_nil
    end
  end
end

RSpec.describe Coradoc::Transform::ClassHelpers do
  # Create a test class that extends the class helpers
  let(:helper_class) do
    Class.new do
      extend Coradoc::Transform::ClassHelpers

      register_transform String, :transform_string
      register_transform Integer, :transform_integer
    end
  end

  describe '.register_transform' do
    it 'registers a transform for a class' do
      expect(helper_class.transform_registry).to have_key(String)
      expect(helper_class.transform_registry[String]).to eq(:transform_string)
    end
  end

  describe '.lookup_transform' do
    it 'finds registered transform' do
      expect(helper_class.lookup_transform('text')).to eq(:transform_string)
      expect(helper_class.lookup_transform(123)).to eq(:transform_integer)
    end

    it 'returns nil for unregistered classes' do
      expect(helper_class.lookup_transform({})).to be_nil
    end

    it 'checks parent classes' do
      # Create a subclass of String (this is a bit tricky in Ruby)
      subclass = Class.new(String)

      expect(helper_class.lookup_transform(subclass.new)).to eq(:transform_string)
    end
  end

  describe '.transform_registered?' do
    it 'returns true for registered classes' do
      expect(helper_class.transform_registered?(String)).to be true
    end

    it 'returns false for unregistered classes' do
      expect(helper_class.transform_registered?(Hash)).to be false
    end
  end

  describe '.clear_transforms' do
    it 'clears all registrations' do
      helper_class.clear_transforms

      expect(helper_class.transform_registry).to be_empty
    end
  end
end
