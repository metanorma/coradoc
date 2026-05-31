# frozen_string_literal: true

require 'coradoc/html/renderer'

module Coradoc
  module Html
    autoload :ConverterBase, "#{__dir__}/converter_base"

    # SPA HTML converter
    #
    # Converts CoreModel documents to SPA HTML5 with embedded Vue.js frontend.
    # Uses the unified Liquid template pipeline.
    class Spa < ConverterBase
      class Configuration < ConverterBase::ConfigurationBase
        attr_accessor :theme_toggle, :reading_progress,
                      :toc_sticky, :toc_levels, :lang,
                      :template_dirs, :dist_dir

        def initialize(**options)
          @theme_toggle = options.fetch(:theme_toggle, true)
          @reading_progress = options.fetch(:reading_progress, true)
          @toc_sticky = options.fetch(:toc_sticky, true)
          @toc_levels = options[:toc_levels] || 2
          @lang = options[:lang] || 'en'
          @template_dirs = options[:template_dirs]
          @dist_dir = options[:dist_dir]
        end

        def to_h
          {
            theme_toggle: @theme_toggle, reading_progress: @reading_progress,
            toc_sticky: @toc_sticky, toc_levels: @toc_levels,
            lang: @lang, template_dirs: @template_dirs, dist_dir: @dist_dir
          }
        end

        def validate!
          return if @toc_levels.is_a?(Integer) && @toc_levels.between?(1, 5)

          raise ConverterBase::ValidationError,
                'TOC levels must be an integer between 1 and 5'
        end
      end

      def convert
        renderer = Renderer.new(template_dirs: @config.template_dirs)

        renderer.render_html5(
          @document,
          layout: :spa,
          lang: @config.lang,
          toc: @config.toc_sticky,
          toc_levels: @config.toc_levels,
          section_numbers: false,
          dist_dir: @config.dist_dir,
          theme_toggle: @config.theme_toggle,
          reading_progress: @config.reading_progress
        )
      end

      private

      def configuration_class
        Configuration
      end
    end
  end
end
