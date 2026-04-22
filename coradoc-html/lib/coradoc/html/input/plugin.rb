# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      class Plugin
        #### Plugin system general

        # Allow building plugins with a shorthand syntax:
        # plugin = Coradoc::Html::Input::Plugin.new do
        #   def name = "Test"
        # end

        def self.new(&block)
          if self == Plugin
            Class.new(Plugin, &block)
          else
            super
          end
        end

        def initialize
          @html_tree_hooks_pre = {}
          @html_tree_hooks_post = {}
        end

        # define name to name a Plugin
        def name
          self.class.name
        end

        #### HTML Tree functionalities

        attr_accessor :html_tree, :coremodel_tree, :output_string

        # Legacy accessors for backward compatibility
        # @deprecated Use coremodel_tree instead. Will be removed in v2.0.
        def coradoc_tree
          warn '[DEPRECATION] `coradoc_tree` is deprecated. Use `coremodel_tree` instead.'
          coremodel_tree
        end

        def coradoc_tree=(value)
          warn '[DEPRECATION] `coradoc_tree=` is deprecated. Use `coremodel_tree=` instead.'
          self.coremodel_tree = value
        end

        # @deprecated Use output_string instead. Will be removed in v2.0.
        def asciidoc_string
          warn '[DEPRECATION] `asciidoc_string` is deprecated. Use `output_string` instead.'
          output_string
        end

        def asciidoc_string=(value)
          warn '[DEPRECATION] `asciidoc_string=` is deprecated. Use `output_string=` instead.'
          self.output_string = value
        end

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
          Coradoc::Html::Input::Converters.process_coradoc(tree, state)
        end

        # @deprecated Use html_tree_process_to_coremodel instead. Will be removed in v2.0.
        def html_tree_process_to_coradoc(tree, state = {})
          warn '[DEPRECATION] `html_tree_process_to_coradoc` is deprecated. Use `html_tree_process_to_coremodel` instead.'
          html_tree_process_to_coremodel(tree, state)
        end

        def html_tree_preview
          Tempfile.open(%w[coradoc .html]) do |i|
            i << html_tree.to_html
            system 'chromium-browser', '--no-sandbox', i.path
          end
        end

        # define preprocess_html_tree to process HTML trees

        # Creates a hook to be called instead of converting an element
        # to a CoreModel node.
        #
        # proc |html_node, state|
        #   coremodel_node
        # end
        def html_tree_add_hook_pre(element, &block)
          @html_tree_hooks_pre[element] = block
        end

        def html_tree_add_hook_pre_by_css(css, &block)
          html_tree.css(css).each do |e|
            html_tree_add_hook_pre(e, &block)
          end
        end

        # Creates a hook to be called after converting an element
        # to a CoreModel node.
        #
        # proc |html_node, coremodel_node, state|
        #   coremodel_node
        # end
        def html_tree_add_hook_post(element, &block)
          @html_tree_hooks_post[element] = block
        end

        def html_tree_add_hook_post_by_css(css, &block)
          html_tree.css(css).each do |e|
            html_tree_add_hook_post(e, &block)
          end
        end

        def html_tree_run_hooks(node, state, &_block)
          hook_pre = @html_tree_hooks_pre[node]
          hook_post = @html_tree_hooks_post[node]

          coremodel = hook_pre.call(node, state) if hook_pre
          coremodel ||= yield node, state

          coremodel = hook_post.call(node, coremodel, state) if hook_post

          coremodel
        end

        #### CoreModel tree functionalities

        # define postprocess_coremodel_tree to change CoreModel tree

        # @deprecated Use postprocess_coremodel_tree instead. Will be removed in v2.0.
        def postprocess_coradoc_tree
          warn '[DEPRECATION] `postprocess_coradoc_tree` is deprecated. Use `postprocess_coremodel_tree` instead.'
          postprocess_coremodel_tree if respond_to?(:postprocess_coremodel_tree)
        end

        #### Output string functionalities

        # define postprocess_output_string to change the output string
        # (regardless of target format)

        # @deprecated Use postprocess_output_string instead. Will be removed in v2.0.
        def postprocess_asciidoc_string
          warn '[DEPRECATION] `postprocess_asciidoc_string` is deprecated. Use `postprocess_output_string` instead.'
          postprocess_output_string if respond_to?(:postprocess_output_string)
        end
      end
    end
  end
end
