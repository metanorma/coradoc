# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/template_caching'
require 'tmpdir'

RSpec.describe Coradoc::Html::TemplateCaching do
  let(:klass) do
    Class.new do
      include Coradoc::Html::TemplateCaching

      attr_reader :cache

      def initialize
        @cache = {}
      end

      def load_test_template(path, cache_key: 'test')
        load_template(cache: @cache, cache_key: cache_key, path: path)
      end
    end
  end

  let(:instance) { klass.new }

  describe '#load_template' do
    it 'returns nil for non-existent path' do
      result = instance.load_test_template('/nonexistent/template.liquid')
      expect(result).to be_nil
    end

    it 'returns nil for nil path' do
      result = instance.load_test_template(nil)
      expect(result).to be_nil
    end

    it 'parses and caches a valid Liquid template' do
      Dir.mktmpdir do |dir|
        template_path = File.join(dir, 'test.liquid')
        File.write(template_path, '<p>{{ content }}</p>')

        result = instance.load_test_template(template_path)
        expect(result).to be_a(Liquid::Template)
        expect(instance.cache['test']).to eq(result)
      end
    end

    it 'returns cached template on subsequent calls' do
      Dir.mktmpdir do |dir|
        template_path = File.join(dir, 'test.liquid')
        File.write(template_path, '<p>hello</p>')

        first = instance.load_test_template(template_path)
        second = instance.load_test_template(template_path)
        expect(first).to equal(second)
      end
    end

    it 'warns and returns nil on Liquid syntax errors' do
      Dir.mktmpdir do |dir|
        template_path = File.join(dir, 'bad.liquid')
        File.write(template_path, '{{ unclosed')

        expect { instance.load_test_template(template_path) }.to output(/Template syntax error/).to_stderr
      end
    end
  end
end
