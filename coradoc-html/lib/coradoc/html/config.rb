# frozen_string_literal: true

module Coradoc
  module Html
    # HTML configuration and options
    module Config
      # Default HTML output options
      DEFAULT_OPTIONS = {
        # Theme system options
        theme: :classic,
        modern: {
          # Appearance
          color_scheme: :glass,
          primary_color: '#6366f1',
          accent_color: '#8b5cf6',

          # Layout
          max_width: '1200px',
          content_width: '65ch',
          sidebar_width: '280px',

          # Features
          theme_toggle: true,
          reading_progress: true,
          back_to_top: true,
          toc_sticky: true,
          copy_code_buttons: true,

          # Animation
          enable_animations: true,
          animation_duration: '300ms',

          # Performance
          lazy_load_images: true
        }.freeze,

        # HTML version
        html_version: :html5,

        # Formatting options
        pretty_print: false,
        indent: '  ',
        line_wrap: 0,

        # Content options
        escape_content: true,
        preserve_whitespace: false,
        convert_line_breaks: true,
        preserve_comments: false,

        # Element options
        use_semantic_elements: true,
        add_css_classes: true,
        add_data_attributes: false,

        # Link options
        external_link_target: nil,
        link_rel: nil,

        # Image options
        image_loading: nil,
        image_decoding: nil,

        # Code block options
        syntax_highlighter: nil,
        syntax_highlighter_opts: {},

        # Table options
        table_border: false,
        table_stripes: false,

        # Attribute options
        preserve_custom_attributes: true,
        attribute_prefix: 'data-',

        # CSS & Styling options
        stylesheet: 'coradoc.css',
        stylesdir: './css',
        linkcss: false,
        copycss: true,
        css_theme: 'professional',
        custom_css: nil,

        # JavaScript options
        javascript: 'coradoc.js',
        jsdir: './js',
        linkjs: false,
        theme_toggle: true,
        toc_interactive: nil,

        # Document metadata options
        author: nil,
        description: nil,
        keywords: nil,
        lang: 'en',
        embedded: false,
        meta_tags: {},

        # Table of contents options
        toc: false,
        toclevels: 2,
        toc_title: 'Table of Contents',
        toc_placement: :auto,

        # Section numbering options
        sectnums: false,
        sectnumlevels: 3,

        # Syntax highlighting options
        source_highlighter: nil,
        highlightjs_theme: 'github',
        pygments_style: 'default',
        rouge_style: 'github'
      }.freeze

      class << self
        # Get default options
        def default_options
          DEFAULT_OPTIONS.dup
        end

        # Merge user options with defaults
        def merge_options(user_options = {})
          default_options.merge(user_options)
        end

        # Validate options
        def validate_options(options)
          valid_keys = DEFAULT_OPTIONS.keys
          invalid_keys = options.keys - valid_keys

          raise ArgumentError, "Invalid options: #{invalid_keys.join(', ')}" unless invalid_keys.empty?

          options
        end

        # Get CSS class for element type
        def css_class_for(element_type, role = nil)
          classes = [element_type.to_s.tr('_', '-')]
          classes << role if role
          classes.join(' ')
        end

        # Get data attribute name
        def data_attribute_name(name, prefix: 'data-')
          "#{prefix}#{name.to_s.tr('_', '-')}"
        end

        # Build element configuration
        def element_config(element_type, options = {})
          {
            tag: html_tag_for(element_type),
            css_class: css_class_for(element_type, options[:role]),
            attributes: options[:attributes] || {}
          }
        end

        # Map element type to HTML tag
        def html_tag_for(element_type)
          TAG_MAPPING[element_type] || 'div'
        end

        # Get stylesheet path
        def stylesheet_path(options = {})
          # When linking, use css_theme-based filename, not the stylesheet option
          css_theme = options[:css_theme] || DEFAULT_OPTIONS[:css_theme]
          stylesheet = "#{css_theme}.css"
          stylesdir = options[:stylesdir] || DEFAULT_OPTIONS[:stylesdir]

          if stylesdir && stylesdir != '.'
            File.join(stylesdir, stylesheet)
          else
            stylesheet
          end
        end

        # Get embedded stylesheet content
        def embedded_stylesheet(options = {})
          css_theme = options[:css_theme] || DEFAULT_OPTIONS[:css_theme]
          stylesheet_name = "#{css_theme}.css"

          # Try themes directory first
          themes_path = File.join(__dir__, 'assets', 'themes', stylesheet_name)
          asset_path = if File.exist?(themes_path)
                         themes_path
                       else
                         # Fall back to assets directory for backward compatibility
                         File.join(__dir__, 'assets', stylesheet_name)
                       end

          css_content = if File.exist?(asset_path)
                          File.read(asset_path)
                        else
                          # Fallback to default coradoc.css
                          default_path = File.join(__dir__, 'assets', 'coradoc.css')
                          File.exist?(default_path) ? File.read(default_path) : ''
                        end

          # Resolve @import statements for embedded CSS
          # @import doesn't work in inline <style> tags
          resolve_css_imports(css_content, File.dirname(asset_path))
        end

        # Resolve @import statements in CSS content
        # @param css_content [String] CSS content with potential @import statements
        # @param base_dir [String] Base directory for resolving relative imports
        # @return [String] CSS content with imports resolved
        def resolve_css_imports(css_content, base_dir)
          # Match @import url('...') or @import url("...") or @import '...' or @import "..."
          css_content.gsub(/@import\s+(?:url\()?['"]([^'"]+)['"]\)?;?/) do
            import_path = ::Regexp.last_match(1)
            full_path = File.join(base_dir, import_path)

            if File.exist?(full_path)
              # Read the imported file and recursively resolve its imports
              imported_content = File.read(full_path)
              resolve_css_imports(imported_content, File.dirname(full_path))
            else
              # Keep the original import if file not found
              ::Regexp.last_match(0)
            end
          end
        end

        # Build CSS link tag
        def css_link_tag(options = {})
          href = stylesheet_path(options)
          %(<link rel="stylesheet" href="#{href}">)
        end

        # Build CSS style tag with embedded content
        def css_style_tag(options = {})
          css_content = embedded_stylesheet(options)
          custom_css = options[:custom_css]

          content = css_content
          content += "\n\n#{custom_css}" if custom_css && !custom_css.empty?

          %(<style>\n#{content}\n</style>)
        end

        # Build custom CSS style tag
        def custom_css_tag(custom_css)
          return '' unless custom_css && !custom_css.empty?

          %(<style>\n#{custom_css}\n</style>)
        end

        # Determine whether to embed or link CSS
        def embed_css?(options = {})
          # Embed if linkcss is false or embedded mode is true
          !options.fetch(:linkcss, DEFAULT_OPTIONS[:linkcss]) ||
            options.fetch(:embedded, DEFAULT_OPTIONS[:embedded])
        end

        # Build complete CSS tags (link or embedded, plus custom)
        def css_tags(options = {})
          tags = []

          if embed_css?(options)
            # Embedded mode: include full stylesheet in style tag
            tags << css_style_tag(options)
          else
            # Linked mode: link to external stylesheet
            tags << css_link_tag(options)
            # Add custom CSS separately if provided
            tags << custom_css_tag(options[:custom_css]) if options[:custom_css]
          end

          tags.join("\n")
        end

        # Determine whether to embed or link JavaScript
        def embed_js?(options = {})
          # Embed if linkjs is false, embedded mode is true, or linkcss is false (to match CSS behavior)
          !options.fetch(:linkjs, DEFAULT_OPTIONS[:linkjs]) ||
            options.fetch(:embedded, DEFAULT_OPTIONS[:embedded]) ||
            !options.fetch(:linkcss, DEFAULT_OPTIONS[:linkcss])
        end

        # Get JavaScript file path
        def javascript_path(options = {})
          javascript = options[:javascript] || DEFAULT_OPTIONS[:javascript]
          jsdir = options[:jsdir] || DEFAULT_OPTIONS[:jsdir]

          if jsdir && jsdir != '.'
            File.join(jsdir, javascript)
          else
            javascript
          end
        end

        # Get embedded JavaScript content
        def embedded_javascript(options = {})
          javascript_name = options[:javascript] || DEFAULT_OPTIONS[:javascript]
          asset_path = File.join(__dir__, 'assets', 'js', javascript_name)

          if File.exist?(asset_path)
            File.read(asset_path)
          else
            ''
          end
        end

        # Build JavaScript link tag
        def js_link_tag(options = {})
          src = javascript_path(options)
          %(<script src="#{src}" defer></script>)
        end

        # Build JavaScript script tag with embedded content
        def js_script_tag(options = {})
          js_content = embedded_javascript(options)
          return '' if js_content.empty?

          %(<script>\n#{js_content}\n</script>)
        end

        # Build complete JavaScript tags (link or embedded)
        def js_tags(options = {})
          return '' if options[:javascript] == false

          tags = []

          tags << if embed_js?(options)
                    # Embedded mode: include full JavaScript in script tag
                    js_script_tag(options)
                  else
                    # Linked mode: link to external JavaScript file
                    js_link_tag(options)
                  end

          tags.join("\n")
        end

        # Check if theme toggle should be enabled
        def theme_toggle?(options = {})
          options.fetch(:theme_toggle, DEFAULT_OPTIONS[:theme_toggle])
        end

        # Check if interactive TOC should be enabled
        def toc_interactive?(options = {})
          # Default to true if TOC is enabled and toc_interactive is not explicitly set to false
          toc_enabled = options.fetch(:toc, DEFAULT_OPTIONS[:toc])
          toc_interactive = options[:toc_interactive]

          # If toc_interactive is nil, default to true when TOC is enabled
          if toc_interactive.nil?
            toc_enabled
          else
            toc_interactive
          end
        end

        # Build syntax highlighter tags (CSS and JS)
        # @param options [Hash] Configuration options
        # @return [String] HTML tags for syntax highlighting
        def syntax_highlighter_tags(options = {})
          highlighter = options[:source_highlighter]
          return '' unless highlighter

          case highlighter.to_sym
          when :highlightjs, :highlight_js, :'highlight.js'
            highlightjs_tags(options)
          when :pygments
            # Pygments requires server-side processing, not implemented for client-side HTML
            ''
          when :rouge
            # Rouge requires server-side processing, not implemented for client-side HTML
            ''
          else
            ''
          end
        end

        # Build Highlight.js tags
        # @param options [Hash] Configuration options
        # @return [String] HTML tags for Highlight.js
        def highlightjs_tags(options = {})
          theme = options[:highlightjs_theme] || DEFAULT_OPTIONS[:highlightjs_theme]
          tags = []

          # Add Highlight.js library
          tags << %(<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/#{theme}.min.css">)
          tags << %(<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>)
          tags << %(<script>hljs.highlightAll();</script>)

          tags.join("\n")
        end

        # Get data attributes for code block
        # @param language [String] Programming language
        # @param options [Hash] Code block options
        # @return [Hash] Data attributes
        def code_block_attributes(language, options = {})
          attrs = {}

          attrs[:class] = "language-#{language}" if language && !language.empty?

          if options[:linenums] || options[:line_numbers]
            attrs[:class] =
              [attrs[:class], 'line-numbers'].compact.join(' ')
          end

          attrs
        end

        # Mapping of Coradoc elements to HTML tags
        TAG_MAPPING = {
          # Sections
          section: 'section',
          header: 'header',

          # Blocks
          paragraph: 'p',
          example: 'div',
          sidebar: 'aside',
          quote: 'blockquote',
          verse: 'div',
          listing: 'pre',
          literal: 'pre',
          source: 'pre',
          open: 'div',

          # Lists
          ordered_list: 'ol',
          unordered_list: 'ul',
          list_item: 'li',
          description_list: 'dl',
          description_term: 'dt',
          description_detail: 'dd',

          # Tables
          table: 'table',
          table_row: 'tr',
          table_cell: 'td',
          table_header: 'th',

          # Inline
          bold: 'strong',
          italic: 'em',
          monospace: 'code',
          highlight: 'mark',
          superscript: 'sup',
          subscript: 'sub',
          underline: 'u',
          strikethrough: 'del',
          small_caps: 'span',

          # Links
          anchor: 'a',
          cross_reference: 'a',

          # Media
          image: 'img',
          video: 'video',
          audio: 'audio',

          # Other
          break: 'hr',
          line_break: 'br',
          admonition: 'div'
        }.freeze
      end
    end
  end
end
