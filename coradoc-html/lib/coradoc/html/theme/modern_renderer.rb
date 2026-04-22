# frozen_string_literal: true

module Coradoc
  module Html
    module Theme
      # Modern theme renderer using Vue.js 3 + Tailwind CSS
      #
      # This renderer generates a complete, self-contained HTML5 document
      # with embedded Vue.js components and Tailwind CSS styling.
      # The modern theme features glass morphism aesthetics and interactive
      # UI components.
      #
      # @example Generate modern HTML output
      #   html = Coradoc::Output::Html.convert_to_html5(document, theme: :modern)
      class ModernRenderer < Base
        # Register this theme
        Registry.register(:modern, self)

        # Default configuration for modern theme
        DEFAULT_CONFIG = {
          color_scheme: :glass,
          primary_color: '#6366f1',    # Indigo-500
          accent_color: '#8b5cf6',     # Violet-500
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
        }.freeze

        # Get template directories (from options or global config)
        #
        # @return [Array<String>]
        def template_dirs
          @options[:template_dirs] || global_template_dirs
        end

        # Check if custom templates are configured and available
        #
        # @return [Boolean]
        def use_custom_templates?
          dirs = template_dirs
          return false if dirs.empty?

          dirs.any? { |dir| File.directory?(dir) }
        end

        # Supported features for modern theme
        #
        # @return [Array<Symbol>] Supported features
        def supported_features
          %i[
            dark_mode
            theme_toggle
            interactive_toc
            reading_progress
            back_to_top
            copy_code_buttons
            lazy_loading
            animations
            glass_morphism
          ]
        end

        # Render document to HTML
        #
        # Generates a complete HTML5 document with Vue.js application.
        #
        # @return [String] Complete HTML5 document
        def render
          render_html5
        end

        # Render complete HTML5 document
        #
        # @return [String] Complete HTML5 document
        def render_html5
          # Merge user options with defaults
          config = DEFAULT_CONFIG.merge(@options[:modern] || {})

          # Serialize document to Vue-compatible format
          document_data = serialize_document

          # Generate Vue application code
          vue_app = generate_vue_app(document_data, config)

          # Generate Tailwind configuration
          tailwind_config = generate_tailwind_config(config)

          # Generate custom CSS
          custom_css = generate_custom_css(config)

          # Build complete HTML document
          build_html_document(vue_app, tailwind_config, custom_css, config)
        end

        private

        # Get global template directories from configuration
        def global_template_dirs
          Coradoc::Html.configuration.template_dirs.map(&:to_s)
        end

        # Serialize document to Vue-compatible data structure
        #
        # @return [Hash] Serialized document data
        def serialize_document
          require_relative 'modern/serializers/document_serializer'
          Serializers::DocumentSerializer.serialize(@document)
        end

        # Generate Vue application code
        #
        # @param document_data [Hash] Serialized document data
        # @param config [Hash] Theme configuration
        # @return [String] Vue application JavaScript
        def generate_vue_app(document_data, config)
          require_relative 'modern/javascript_generator'
          JavascriptGenerator.generate(document_data, config)
        end

        # Generate Tailwind CSS configuration
        #
        # @param config [Hash] Theme configuration
        # @return [String] Tailwind configuration script
        def generate_tailwind_config(config)
          require_relative 'modern/tailwind_config_builder'
          TailwindConfigBuilder.build(config)
        end

        # Generate custom CSS for glass morphism and special effects
        #
        # @param config [Hash] Theme configuration
        # @return [String] Custom CSS
        def generate_custom_css(config)
          require_relative 'modern/css_generator'
          require_relative 'modern/components/ui_components'

          # Use enhanced CSS from UIComponents module
          UIComponents.enhanced_css(config)
        end

        # Build complete HTML document
        #
        # @param vue_app [String] Vue application code
        # @param tailwind_config [String] Tailwind configuration
        # @param custom_css [String] Custom CSS
        # @param config [Hash] Theme configuration
        # @return [String] Complete HTML5 document
        def build_html_document(vue_app, tailwind_config, custom_css, config)
          lang = @options[:lang] || 'en'
          title = extract_document_title

          # Meta tags
          meta_tags = build_meta_tags(config)

          # Open Graph tags if enabled
          og_tags = config[:open_graph] ? build_open_graph_tags : ''

          # Vue and Tailwind CDN links
          cdn_links = build_cdn_links

          <<~HTML
            <!DOCTYPE html>
            <html lang="#{lang}" class="#{config[:color_scheme]}">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              #{meta_tags}
              <title>#{escape_html(title)}</title>
              #{og_tags}
              #{cdn_links}
              <script>#{tailwind_config}</script>
              <style>#{custom_css}</style>
            </head>
            <body class="bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 min-h-screen transition-colors duration-300">
              <div id="app"></div>
              <script>#{vue_app}</script>
            </body>
            </html>
          HTML
        end

        # Build meta tags
        #
        # @param config [Hash] Theme configuration
        # @return [String] Meta tags HTML
        def build_meta_tags(config)
          tags = []

          # Author
          tags << %(<meta name="author" content="#{escape_attr(@options[:author])}">) if @options[:author]

          # Description
          description = config[:meta_description] || @options[:description]
          tags << %(<meta name="description" content="#{escape_attr(description)}">) if description

          # Keywords
          keywords = config[:meta_keywords] || @options[:keywords]
          tags << %(<meta name="keywords" content="#{escape_attr(keywords)}">) if keywords

          # Generator
          tags << %{<meta name="generator" content="Coradoc #{Coradoc::VERSION} (Modern Theme)">}

          # Timestamp
          tags << %(<meta name="generated" content="#{Time.now.utc.iso8601}">)

          # Custom meta tags
          if @options[:meta_tags].is_a?(Hash)
            @options[:meta_tags].each do |name, content|
              tags << %(<meta name="#{escape_attr(name)}" content="#{escape_attr(content)}">)
            end
          end

          tags.join("\n  ")
        end

        # Build Open Graph tags
        #
        # @return [String] Open Graph tags HTML
        def build_open_graph_tags
          title = extract_document_title
          <<~HTML
            <meta property="og:title" content="#{escape_html(title)}">
            <meta property="og:type" content="article">
            <meta property="og:generator" content="Coradoc #{Coradoc::VERSION}">
          HTML
        end

        # Build CDN links for Vue and Tailwind
        #
        # @return [String] CDN link tags
        def build_cdn_links
          <<~HTML
            <!-- Vue.js 3 (with template compiler for runtime compilation) -->
            <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>

            <!-- Tailwind CSS 3.4 -->
            <script src="https://cdn.tailwindcss.com"></script>
          HTML
        end
      end
    end
  end
end
