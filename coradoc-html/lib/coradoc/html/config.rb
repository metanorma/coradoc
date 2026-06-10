# frozen_string_literal: true

module Coradoc
  module Html
    module Config
      DEFAULT_LANG = 'en'
      DEFAULT_TITLE = 'Untitled'

      DEFAULT_OPTIONS = {
        theme: :classic,
        modern: {
          color_scheme: :glass,
          primary_color: '#6366f1',
          accent_color: '#8b5cf6',
          max_width: '1200px',
          content_width: '65ch',
          sidebar_width: '280px',
          theme_toggle: true,
          reading_progress: true,
          back_to_top: true,
          toc_sticky: true,
          copy_code_buttons: true,
          enable_animations: true,
          animation_duration: '300ms',
          lazy_load_images: true
        }.freeze,
        html_version: :html5,
        pretty_print: false,
        indent: '  ',
        line_wrap: 0,
        escape_content: true,
        preserve_whitespace: false,
        convert_line_breaks: true,
        preserve_comments: false,
        use_semantic_elements: true,
        add_css_classes: true,
        add_data_attributes: false,
        external_link_target: nil,
        link_rel: nil,
        image_loading: nil,
        image_decoding: nil,
        syntax_highlighter: nil,
        syntax_highlighter_opts: {},
        table_border: false,
        table_stripes: false,
        preserve_custom_attributes: true,
        attribute_prefix: 'data-',
        stylesheet: 'coradoc.css',
        stylesdir: './css',
        linkcss: false,
        copycss: true,
        css_theme: 'professional',
        custom_css: nil,
        javascript: 'coradoc.js',
        jsdir: './js',
        linkjs: false,
        theme_toggle: true,
        toc_interactive: nil,
        author: nil,
        description: nil,
        keywords: nil,
        lang: 'en',
        embedded: false,
        meta_tags: {},
        toc: false,
        toclevels: 2,
        toc_title: 'Table of Contents',
        toc_placement: :auto,
        sectnums: false,
        sectnumlevels: 3,
        source_highlighter: nil,
        highlightjs_theme: 'github',
        pygments_style: 'default',
        rouge_style: 'github'
      }.freeze

      class << self
        def default_options
          DEFAULT_OPTIONS.dup
        end

        def merge_options(user_options = {})
          default_options.merge(user_options)
        end

        def validate_options(options)
          valid_keys = DEFAULT_OPTIONS.keys
          invalid_keys = options.keys - valid_keys

          raise ArgumentError, "Invalid options: #{invalid_keys.join(', ')}" unless invalid_keys.empty?

          options
        end

        def css_class_for(element_type, role = nil)
          classes = [element_type.to_s.tr('_', '-')]
          classes << role if role
          classes.join(' ')
        end

        def data_attribute_name(name, prefix: 'data-')
          "#{prefix}#{name.to_s.tr('_', '-')}"
        end

        def element_config(element_type, options = {})
          {
            tag: html_tag_for(element_type),
            css_class: css_class_for(element_type, options[:role]),
            attributes: options[:attributes] || {}
          }
        end

        def html_tag_for(element_type)
          TagMapping.tag_for(element_type)
        end

        def code_block_attributes(language, options = {})
          attrs = {}
          attrs[:class] = "language-#{language}" if language && !language.empty?

          attrs[:class] = [attrs[:class], 'line-numbers'].compact.join(' ') if options[:linenums] || options[:line_numbers]

          attrs
        end

        def theme_toggle?(options = {})
          options.fetch(:theme_toggle, DEFAULT_OPTIONS[:theme_toggle])
        end

        def toc_interactive?(options = {})
          toc_enabled = options.fetch(:toc, DEFAULT_OPTIONS[:toc])
          toc_interactive = options[:toc_interactive]
          toc_interactive.nil? ? toc_enabled : toc_interactive
        end
      end

      ASSET_METHODS = %i[
        stylesheet_path embedded_stylesheet resolve_css_imports
        css_link_tag css_style_tag custom_css_tag embed_css? css_tags
        javascript_path embedded_javascript
        js_link_tag js_script_tag embed_js? js_tags
        syntax_highlighter_tags highlightjs_tags
      ].freeze

      ASSET_METHODS.each do |method|
        define_method(method) { |*args, **kwargs, &blk| AssetResolver.public_send(method, *args, **kwargs, &blk) }
      end
      module_function(*ASSET_METHODS)
    end
  end
end
