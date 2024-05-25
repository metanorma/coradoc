module Coradoc::ReverseAdoc
  class Plugin
    #### Plugin system general

    # Allow building plugins with a shorthand syntax:
    # plugin = Coradoc::ReverseAdoc::Plugin.new do
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

    attr_accessor :html_tree

    def html_tree_change_tag_name_by_css(css, new_name)
      html_tree.css(css).each do |e|
        e.name = new_name
      end
    end

    def html_tree_remove_by_css(css)
      html_tree.css(css).each(&:remove)
    end

    # define preprocess_html_tree to process HTML trees

    # Creates a hook to be called instead of converting an element
    # to a Coradoc node.
    #
    # proc |html_node, state|
    #   coradoc_node
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
    # to a Coradoc node.
    #
    # proc |html_node, coradoc_node, state|
    #   coradoc_node
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

      coradoc = if hook_pre
                  hook_pre.(node, state)
                else
                  yield node, state
                end

      if hook_post
        coradoc = hook_post.(node, coradoc, state)
      end

      coradoc
    end
  end
end
