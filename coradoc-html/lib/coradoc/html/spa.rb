# frozen_string_literal: true

require_relative 'converter_base'

module Coradoc
  module Html
    # SPA (Single Page Application) HTML converter
    #
    # Converts Coradoc::CoreModel::StructuralElement to a modern Vue.js + Tailwind CSS
    # single-page application with glass morphism aesthetics.
    #
    # Features:
    # - Vue.js 3 reactive components
    # - Tailwind CSS styling
    # - Glass morphism design
    # - Dark/light theme toggle
    # - Reading progress indicator
    # - Sticky TOC sidebar
    # - Copy code buttons
    # - Smooth animations
    #
    # @example Basic usage
    #   doc = Coradoc.parse_file('document.adoc')
    #   html = Coradoc::Html::Spa.convert(doc)
    #
    # @example With configuration
    #   config = Coradoc::Html::Spa::Configuration.new(
    #     theme_variant: :glass,
    #     primary_color: '#6366f1',
    #     theme_toggle: true,
    #     reading_progress: true
    #   )
    #   html = Coradoc::Html::Spa.convert(doc, config)
    #
    # @example Write to file
    #   Coradoc::Html::Spa.to_file(doc, 'output.html', config)
    class Spa < ConverterBase
      # Configuration for SPA HTML output
      #
      # Plain Ruby configuration class with accessors and defaults.
      class Configuration
        # How to deliver assets (:embedded always for SPA)
        attr_accessor :asset_delivery

        # Theme appearance variant (:glass, :minimal, :vibrant)
        attr_accessor :theme_variant

        # Primary color (hex string, e.g., '#6366f1')
        attr_accessor :primary_color

        # Accent color (hex string, e.g., '#8b5cf6')
        attr_accessor :accent_color

        # Whether to enable theme toggle (dark/light mode)
        attr_accessor :theme_toggle

        # Whether to show reading progress bar
        attr_accessor :reading_progress

        # Whether to show back to top button
        attr_accessor :back_to_top

        # Whether TOC should be sticky
        attr_accessor :toc_sticky

        # Whether to add copy buttons to code blocks
        attr_accessor :copy_code_buttons

        # TOC levels to include (1-5)
        attr_accessor :toc_levels

        # TOC title text
        attr_accessor :toc_title

        # Whether to enable animations
        attr_accessor :enable_animations

        # Animation duration (CSS value, e.g., '300ms')
        attr_accessor :animation_duration

        # Whether to lazy load images
        attr_accessor :lazy_load_images

        # Maximum width of the container (CSS value)
        attr_accessor :max_width

        # Content width (CSS value)
        attr_accessor :content_width

        # Sidebar width for TOC (CSS value)
        attr_accessor :sidebar_width

        # Language attribute for HTML
        attr_accessor :lang

        # Custom meta description
        attr_accessor :meta_description

        # Custom meta keywords
        attr_accessor :meta_keywords

        # Enable Open Graph meta tags
        attr_accessor :open_graph

        # Valid theme variants
        VALID_THEME_VARIANTS = %i[glass minimal vibrant].freeze

        # Initialize configuration with options
        #
        # @param options [Hash] Configuration options
        def initialize(**options)
          @asset_delivery = options[:asset_delivery] || :embedded
          @theme_variant = options[:theme_variant] || :glass
          @primary_color = options[:primary_color] || '#6366f1'
          @accent_color = options[:accent_color] || '#8b5cf6'
          @theme_toggle = options.fetch(:theme_toggle, true)
          @reading_progress = options.fetch(:reading_progress, true)
          @back_to_top = options.fetch(:back_to_top, true)
          @toc_sticky = options.fetch(:toc_sticky, true)
          @copy_code_buttons = options.fetch(:copy_code_buttons, true)
          @toc_levels = options[:toc_levels] || 2
          @toc_title = options[:toc_title] || 'Table of Contents'
          @enable_animations = options.fetch(:enable_animations, true)
          @animation_duration = options[:animation_duration] || '300ms'
          @lazy_load_images = options.fetch(:lazy_load_images, true)
          @max_width = options[:max_width] || '1200px'
          @content_width = options[:content_width] || '65ch'
          @sidebar_width = options[:sidebar_width] || '280px'
          @lang = options[:lang] || 'en'
          @meta_description = options[:meta_description]
          @meta_keywords = options[:meta_keywords]
          @open_graph = options.fetch(:open_graph, false)
        end

        # Default configuration
        #
        # @return [Configuration] Default configuration instance
        def self.defaults
          new
        end

        # Merge with another configuration or hash
        #
        # @param other [Hash, Configuration] Configuration to merge
        # @return [Configuration] New merged configuration
        def merge(other)
          other_hash = other.is_a?(Configuration) ? other.to_h : other.to_h.transform_keys(&:to_sym)
          self.class.new(**to_h.merge(other_hash))
        end

        # Convert to hash
        #
        # @return [Hash] Configuration as hash
        def to_h
          {
            asset_delivery: @asset_delivery,
            theme_variant: @theme_variant,
            primary_color: @primary_color,
            accent_color: @accent_color,
            theme_toggle: @theme_toggle,
            reading_progress: @reading_progress,
            back_to_top: @back_to_top,
            toc_sticky: @toc_sticky,
            copy_code_buttons: @copy_code_buttons,
            toc_levels: @toc_levels,
            toc_title: @toc_title,
            enable_animations: @enable_animations,
            animation_duration: @animation_duration,
            lazy_load_images: @lazy_load_images,
            max_width: @max_width,
            content_width: @content_width,
            sidebar_width: @sidebar_width,
            lang: @lang,
            meta_description: @meta_description,
            meta_keywords: @meta_keywords,
            open_graph: @open_graph
          }
        end

        # Validate configuration
        #
        # @raise [ConverterBase::ValidationError] if configuration is invalid
        def validate!
          validate_hex_color(@primary_color, 'primary_color')
          validate_hex_color(@accent_color, 'accent_color')
          validate_css_value(@max_width, 'max_width')
          validate_css_value(@content_width, 'content_width')
          validate_css_value(@sidebar_width, 'sidebar_width')
          validate_css_value(@animation_duration, 'animation_duration')

          unless VALID_THEME_VARIANTS.include?(@theme_variant.to_sym)
            raise ConverterBase::ValidationError,
                  "Invalid theme variant: #{@theme_variant}. " \
                  "Valid variants: #{VALID_THEME_VARIANTS.join(', ')}"
          end

          return if @toc_levels.is_a?(Integer) && @toc_levels.between?(1, 5)

          raise ConverterBase::ValidationError,
                'TOC levels must be an integer between 1 and 5'
        end

        # Convert to options hash for ModernRenderer
        #
        # @return [Hash] Options hash for the modern renderer
        def to_renderer_options
          {
            modern: to_h,
            lang: @lang,
            toc: @toc_sticky,
            toclevels: @toc_levels,
            toc_title: @toc_title
          }
        end

        private

        # Validate hex color format
        #
        # @param color [String] Color string to validate
        # @param field_name [String] Field name for error message
        # @raise [ConverterBase::ValidationError] if invalid
        def validate_hex_color(color, field_name)
          return unless color

          return if color.match?(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/)

          raise ConverterBase::ValidationError,
                "Invalid hex color for #{field_name}: #{color}. " \
                'Expected format: #RRGGBB or #RGB'
        end

        # Validate CSS dimension value
        #
        # @param value [String] CSS value to validate
        # @param field_name [String] Field name for error message
        # @raise [ConverterBase::ValidationError] if invalid
        def validate_css_value(value, field_name)
          return unless value

          # Allow common CSS units
          return if value.match?(/^\d+(\.\d+)?(px|%|ch|em|rem|vw|vh|ms|s)$/)

          raise ConverterBase::ValidationError,
                "Invalid CSS value for #{field_name}: #{value}. " \
                'Expected format: number with unit (px, %, ch, em, rem, vw, vh, ms, s)'
        end
      end

      # Convert document to SPA HTML
      #
      # @return [String] Complete HTML5 document with Vue.js application
      def convert
        # Build options hash for ModernRenderer
        options = @config.to_renderer_options

        # Use ModernRenderer to generate HTML
        renderer = Html::Theme::ModernRenderer.new(@document, options)
        renderer.render_html5
      end

      private

      # Build configuration from options
      #
      # @param config [Hash, Configuration] Configuration options
      # @return [Configuration] Configuration object
      def build_config(config)
        case config
        when Configuration
          config.validate!
          config
        when Hash
          Configuration.new(**config)
        else
          Configuration.defaults
        end
      end

      # Output processor interface: unique identifier
      #
      # @return [Symbol] Processor identifier
      def self.processor_id
        :html_spa
      end

      # Output processor interface: check if this processor handles the file
      #
      # @param filename [String] Output filename
      # @return [Boolean] true if this processor can handle the file
      def self.processor_match?(filename)
        filename.downcase.end_with?('.html', '.htm')
      end

      # Output processor interface: execute the conversion
      #
      # @param input [Hash] Input from the converter (contains document)
      # @param options [Hash] Output options
      # @return [Hash] Hash with nil => HTML output
      def self.processor_execute(input, options = {})
        # Handle hash input from converter pipeline
        document = input.is_a?(Hash) ? (input[:document] || input.values.first) : input
        html = convert(document, options)
        # Return in format expected by converter (hash with filename => content)
        { nil => html }
      end
    end
  end
end
