# frozen_string_literal: true

require 'coradoc/html/renderer'

module Coradoc
  module Html
    autoload :ConverterBase, "#{__dir__}/converter_base"

    # Static HTML converter
    #
    # Converts CoreModel documents to static HTML5 output using
    # the unified Liquid template pipeline.
    class Static < ConverterBase
      class Configuration < ConverterBase::ConfigurationBase
        attribute :include_toc, default: false
        attribute :toc_levels, default: 2
        attribute :section_numbering, default: false
        attribute :section_numbering_levels, default: 3
        attribute :lang, default: 'en'
        attribute :meta_tags, default: {}
        attribute :custom_css
        attribute :embedded, default: false
        attribute :template_dirs

        def validate!
          range_check(:toc_levels, 1, 5, label: 'TOC levels')
          range_check(:section_numbering_levels, 1, 6, label: 'Section numbering levels')
        end
      end

      def convert
        renderer = Renderer.new(template_dirs: @config.template_dirs)

        if @config.embedded
          renderer.render(@document)
        else
          renderer.render_html5(
            @document,
            layout: :static,
            lang: @config.lang,
            author: @config.meta_tags[:author],
            description: @config.meta_tags[:description],
            custom_css: @config.custom_css,
            toc: @config.include_toc,
            section_numbers: @config.section_numbering,
            section_number_levels: @config.section_numbering_levels,
            toc_levels: @config.toc_levels
          )
        end
      end

      private

      def configuration_class
        Configuration
      end
    end
  end
end
