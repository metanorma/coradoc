# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe Coradoc::Html::Plugin do
  let(:plugin_class) { described_class.new }
  let(:plugin) { plugin_class.new }

  describe '.new(&block)' do
    it 'creates a subclass when called on Plugin directly' do
      klass = described_class.new do
        def name
          'TestPlugin'
        end
      end
      expect(klass).to be < described_class
      instance = klass.new
      expect(instance.name).to eq('TestPlugin')
    end

    it 'creates an instance when called on a subclass' do
      klass = described_class.new do
        def name
          'Sub'
        end
      end
      instance = klass.new
      expect(instance).to be_a(described_class)
    end
  end

  describe '#name' do
    it 'returns the class name' do
      named_plugin = Class.new(described_class) do
        def name
          self.class.name || 'AnonymousPlugin'
        end
      end
      instance = named_plugin.new
      expect(instance.name).to eq('AnonymousPlugin')
    end
  end

  describe '#preprocess_html_tree' do
    it 'is a no-op by default' do
      expect { plugin.preprocess_html_tree }.not_to raise_error
    end
  end

  describe '#postprocess_coremodel_tree' do
    it 'is a no-op by default' do
      expect { plugin.postprocess_coremodel_tree }.not_to raise_error
    end
  end

  describe '#postprocess_output_string' do
    it 'is a no-op by default' do
      expect { plugin.postprocess_output_string }.not_to raise_error
    end
  end

  describe 'HTML tree manipulation' do
    let(:html) { '<div><p class="remove">gone</p><p class="keep">stay</p></div>' }
    let(:doc) { Nokogiri::HTML.fragment(html) }

    before { plugin.html_tree = doc }

    describe '#html_tree_change_tag_name_by_css' do
      it 'changes tag names matching CSS selector' do
        plugin.html_tree_change_tag_name_by_css('p.remove', 'span')
        expect(doc.at_css('span')).not_to be_nil
        expect(doc.css('span').first.text).to eq('gone')
      end
    end

    describe '#html_tree_change_properties_by_css' do
      it 'changes properties on matching elements' do
        el = doc.at_css('p.keep')
        plugin.html_tree_change_properties_by_css('p.keep', class: 'kept', id: 'test')
        expect(el['class']).to eq('kept')
        expect(el['id']).to eq('test')
      end
    end

    describe '#html_tree_remove_by_css' do
      it 'removes elements matching CSS selector' do
        plugin.html_tree_remove_by_css('p.remove')
        expect(doc.at_css('p.remove')).to be_nil
        expect(doc.at_css('p.keep')).not_to be_nil
      end
    end

    describe '#html_tree_replace_with_children_by_css' do
      it 'replaces elements with their children' do
        outer = '<div><wrap><p>inner</p></wrap></div>'
        nested_doc = Nokogiri::HTML.fragment(outer)
        plugin.html_tree = nested_doc
        plugin.html_tree_replace_with_children_by_css('wrap')
        expect(nested_doc.at_css('wrap')).to be_nil
        expect(nested_doc.at_css('p').text).to eq('inner')
      end
    end
  end

  describe '#html_tree_process_to_coremodel' do
    it 'processes an HTML tree to CoreModel' do
      doc = Nokogiri::HTML('<p>Hello</p>')
      result = plugin.html_tree_process_to_coremodel(doc.root)
      expect(result).not_to be_nil
    end
  end

  describe 'hooks' do
    let(:doc) { Nokogiri::HTML.fragment('<p>test</p>') }
    let(:node) { doc.at_css('p') }

    before { plugin.html_tree = doc }

    describe '#html_tree_add_hook_pre and #html_tree_run_hooks' do
      it 'runs pre-hook before the block' do
        pre_result = CoreModel::Block.new(block_semantic_type: :paragraph, content: 'hooked')
        plugin.html_tree_add_hook_pre(node) { |_n, _s| pre_result }

        result = plugin.html_tree_run_hooks(node, {}) { |_n, _s| 'block_result' }
        expect(result).to eq(pre_result)
      end
    end

    describe '#html_tree_add_hook_post and #html_tree_run_hooks' do
      it 'runs post-hook after the block' do
        post_result = CoreModel::Block.new(block_semantic_type: :paragraph, content: 'post')
        plugin.html_tree_add_hook_post(node) { |_n, _coremodel, _s| post_result }

        result = plugin.html_tree_run_hooks(node, {}) { |_n, _s| 'block_result' }
        expect(result).to eq(post_result)
      end
    end

    describe '#html_tree_add_hook_pre_by_css' do
      it 'adds pre-hooks to elements matching CSS' do
        doc = Nokogiri::HTML.fragment('<p>one</p><p>two</p>')
        plugin.html_tree = doc
        nodes = doc.css('p')

        called = 0
        plugin.html_tree_add_hook_pre_by_css('p') do |_n, _s|
          called += 1
          nil
        end
        nodes.each { |n| plugin.html_tree_run_hooks(n, {}) { |_n, _s| 'default' } }
        expect(called).to eq(2)
      end
    end
  end

  describe 'accessors' do
    it 'allows setting and getting html_tree' do
      doc = Nokogiri::HTML.fragment('<div/>')
      plugin.html_tree = doc
      expect(plugin.html_tree).to eq(doc)
    end

    it 'allows setting and getting coremodel_tree' do
      tree = CoreModel::Block.new(block_semantic_type: :paragraph, content: 'test')
      plugin.coremodel_tree = tree
      expect(plugin.coremodel_tree).to eq(tree)
    end

    it 'allows setting and getting output_string' do
      plugin.output_string = 'result'
      expect(plugin.output_string).to eq('result')
    end
  end
end
