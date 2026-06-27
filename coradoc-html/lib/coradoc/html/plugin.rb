# frozen_string_literal: true

module Coradoc
  module Html
    class Plugin
      def self.new(&)
        if self == Plugin
          Class.new(Plugin, &)
        else
          super
        end
      end

      def initialize
        @html_tree_hooks_pre = {}
        @html_tree_hooks_post = {}
      end

      def name
        self.class.name
      end

      def preprocess_html_tree; end
      def postprocess_coremodel_tree; end
      def postprocess_output_string; end

      attr_accessor :html_tree, :coremodel_tree, :output_string

      def html_tree_change_tag_name_by_css(css, new_name)
        html_tree.css(css).each do |e|
          e.name = new_name
        end
      end

      def html_tree_change_properties_by_css(css, properties)
        html_tree.css(css).each do |e|
          properties.each do |k, v|
            e[k.to_s] = v
          end
        end
      end

      def html_tree_remove_by_css(css)
        html_tree.css(css).each(&:remove)
      end

      def html_tree_replace_with_children_by_css(css)
        html_tree.css(css).each do |e|
          e.replace(e.children)
        end
      end

      def html_tree_process_to_coremodel(tree, state = {})
        Coradoc::Html::Converters.process_coradoc(tree, state)
      end

      def html_tree_add_hook_pre(element, &block)
        @html_tree_hooks_pre[element] = block
      end

      def html_tree_add_hook_pre_by_css(css, &block)
        html_tree.css(css).each do |e|
          html_tree_add_hook_pre(e, &block)
        end
      end

      def html_tree_add_hook_post(element, &block)
        @html_tree_hooks_post[element] = block
      end

      def html_tree_add_hook_post_by_css(css, &block)
        html_tree.css(css).each do |e|
          html_tree_add_hook_post(e, &block)
        end
      end

      def html_tree_run_hooks(node, state, &)
        hook_pre = @html_tree_hooks_pre[node]
        hook_post = @html_tree_hooks_post[node]

        coremodel = hook_pre.call(node, state) if hook_pre
        coremodel ||= yield node, state

        coremodel = hook_post.call(node, coremodel, state) if hook_post

        coremodel
      end
    end
  end
end
