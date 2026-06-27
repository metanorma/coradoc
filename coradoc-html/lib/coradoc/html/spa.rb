# frozen_string_literal: true

module Coradoc
  module Html
    autoload :ConverterBase, "#{__dir__}/converter_base"

    # SPA HTML converter
    #
    # Converts CoreModel documents to SPA HTML5 with embedded Vue.js frontend.
    # Uses the unified Liquid template pipeline.
    class Spa < ConverterBase
      class Configuration < ConverterBase::ConfigurationBase
        attribute :theme_toggle, default: true
        attribute :reading_progress, default: true
        attribute :toc_sticky, default: true
        attribute :toc_levels, default: 2
        attribute :lang, default: 'en'
        attribute :template_dirs
        attribute :dist_dir

        def validate!
          range_check(:toc_levels, 1, 5, label: 'TOC levels')
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
