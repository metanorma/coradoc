# frozen_string_literal: true

require_relative 'converter_base'

module Coradoc
  module Html
    # Static HTML converter
    #
    # Converts CoreModel documents to static HTML5 output.
    # This converter produces traditional HTML with external or embedded CSS/JS.
    #
    # @example Basic usage
    #   doc = Coradoc.parse_file('document.adoc')
    #   html = Coradoc::Html::Static.convert(doc)
    #
    # @example With configuration
    #   config = Coradoc::Html::Static::Configuration.new(
    #     css_theme: :professional,
    #     include_toc: true,
    #     theme_toggle: true
    #   )
    #   html = Coradoc::Html::Static.convert(doc, config)
    #
    # @example Write to file
    #   Coradoc::Html::Static.to_file(doc, 'output.html', config)
    class Static < ConverterBase
      # Configuration for Static HTML output
      #
      # Plain Ruby configuration class with accessors and defaults.
      class Configuration
        # CSS theme to use (:professional, :academic, :tech)
        attr_accessor :css_theme

        # How to deliver assets (:embedded, :external)
        attr_accessor :asset_delivery

        # Whether to include table of contents
        attr_accessor :include_toc

        # TOC levels to include (1-5)
        attr_accessor :toc_levels

        # TOC title text
        attr_accessor :toc_title

        # TOC placement (:auto, :left, :right, :preamble)
        attr_accessor :toc_placement

        # Whether to enable theme toggle (dark/light mode)
        attr_accessor :theme_toggle

        # Whether to preserve comments in output
        attr_accessor :preserve_comments

        # Whether to apply section numbering
        attr_accessor :section_numbering

        # Maximum section level for numbering
        attr_accessor :section_numbering_levels

        # Language attribute for HTML
        attr_accessor :lang

        # Custom meta tags
        attr_accessor :meta_tags

        # Custom CSS to append
        attr_accessor :custom_css

        # Whether to embed output (no full HTML document)
        attr_accessor :embedded

        # Valid CSS themes
        VALID_CSS_THEMES = %i[professional academic tech].freeze

        # Valid asset delivery methods
        VALID_ASSET_DELIVERIES = %i[embedded external].freeze

        # Valid TOC placements
        VALID_TOC_PLACEMENTS = %i[auto left right preamble].freeze

        # Initialize configuration with options
        #
        # @param options [Hash] Configuration options
        def initialize(**options)
          @css_theme = options[:css_theme] || :professional
          @asset_delivery = options[:asset_delivery] || :embedded
          @include_toc = options.fetch(:include_toc, false)
          @toc_levels = options[:toc_levels] || 2
          @toc_title = options[:toc_title] || 'Table of Contents'
          @toc_placement = options[:toc_placement] || :auto
          @theme_toggle = options.fetch(:theme_toggle, true)
          @preserve_comments = options.fetch(:preserve_comments, false)
          @section_numbering = options.fetch(:section_numbering, false)
          @section_numbering_levels = options[:section_numbering_levels] || 3
          @lang = options[:lang] || 'en'
          @meta_tags = options[:meta_tags] || {}
          @custom_css = options[:custom_css]
          @embedded = options.fetch(:embedded, false)
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
            css_theme: @css_theme,
            asset_delivery: @asset_delivery,
            include_toc: @include_toc,
            toc_levels: @toc_levels,
            toc_title: @toc_title,
            toc_placement: @toc_placement,
            theme_toggle: @theme_toggle,
            preserve_comments: @preserve_comments,
            section_numbering: @section_numbering,
            section_numbering_levels: @section_numbering_levels,
            lang: @lang,
            meta_tags: @meta_tags,
            custom_css: @custom_css,
            embedded: @embedded
          }
        end

        # Validate configuration
        #
        # @raise [ConverterBase::ValidationError] if configuration is invalid
        def validate!
          unless VALID_CSS_THEMES.include?(@css_theme.to_sym)
            raise ConverterBase::ValidationError,
                  "Invalid CSS theme: #{@css_theme}. " \
                  "Valid themes: #{VALID_CSS_THEMES.join(', ')}"
          end

          unless VALID_ASSET_DELIVERIES.include?(@asset_delivery.to_sym)
            raise ConverterBase::ValidationError,
                  "Invalid asset delivery: #{@asset_delivery}. " \
                  "Valid options: #{VALID_ASSET_DELIVERIES.join(', ')}"
          end

          if @include_toc && !VALID_TOC_PLACEMENTS.include?(@toc_placement.to_sym)
            raise ConverterBase::ValidationError,
                  "Invalid TOC placement: #{@toc_placement}. " \
                  "Valid options: #{VALID_TOC_PLACEMENTS.join(', ')}"
          end

          unless @toc_levels.is_a?(Integer) && @toc_levels.between?(1, 5)
            raise ConverterBase::ValidationError,
                  'TOC levels must be an integer between 1 and 5'
          end

          unless @section_numbering_levels.is_a?(Integer) &&
                 @section_numbering_levels.between?(1, 6)
            raise ConverterBase::ValidationError,
                  'Section numbering levels must be an integer between 1 and 6'
          end
        end

        # Check if assets should be embedded
        #
        # @return [Boolean] true if assets should be embedded
        def embed_assets?
          @asset_delivery == :embedded || @embedded
        end

        # Check if external assets should be linked
        #
        # @return [Boolean] true if assets should be linked
        def link_assets?
          !embed_assets?
        end
      end

      # Convert document to static HTML
      #
      # @return [String] Complete HTML5 document or fragment (if embedded mode)
      def convert
        # Build options hash for ClassicRenderer
        options = build_renderer_options

        # Use ClassicRenderer to generate HTML
        renderer = Html::Theme::ClassicRenderer.new(@document, options)

        if @config.embedded
          renderer.render
        else
          renderer.render_html5
        end
      end

      private

      # Build options hash for ClassicRenderer
      #
      # @return [Hash] Options for the classic renderer
      def build_renderer_options
        # When TOC is enabled with auto placement, default to left sidebar
        effective_toc_placement = if @config.include_toc && @config.toc_placement == :auto
                                    :left
                                  else
                                    @config.toc_placement
                                  end

        options = {
          theme: :classic,
          css_theme: @config.css_theme.to_s,
          linkcss: @config.link_assets?,
          copycss: true,
          toc: @config.include_toc,
          toclevels: @config.toc_levels,
          toc_title: @config.toc_title,
          toc_placement: effective_toc_placement,
          theme_toggle: @config.theme_toggle,
          preserve_comments: @config.preserve_comments,
          sectnums: @config.section_numbering,
          sectnumlevels: @config.section_numbering_levels,
          lang: @config.lang,
          meta_tags: @config.meta_tags,
          custom_css: @config.custom_css,
          embedded: @config.embedded
        }

        # Handle JavaScript based on asset delivery
        options[:linkjs] = if @config.embed_assets?
                             false
                           else
                             true
                           end

        options
      end

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
        :html_static
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
