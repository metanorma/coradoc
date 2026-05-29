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
        attr_accessor :include_toc, :toc_levels,
                      :section_numbering, :section_numbering_levels,
                      :lang, :meta_tags, :custom_css, :embedded,
                      :template_dirs

        def initialize(**options)
          @include_toc = options.fetch(:include_toc, false)
          @toc_levels = options[:toc_levels] || 2
          @section_numbering = options.fetch(:section_numbering, false)
          @section_numbering_levels = options[:section_numbering_levels] || 3
          @lang = options[:lang] || 'en'
          @meta_tags = options[:meta_tags] || {}
          @custom_css = options[:custom_css]
          @embedded = options.fetch(:embedded, false)
          @template_dirs = options[:template_dirs]
        end

        def to_h
          {
            include_toc: @include_toc, toc_levels: @toc_levels,
            section_numbering: @section_numbering,
            section_numbering_levels: @section_numbering_levels,
            lang: @lang, meta_tags: @meta_tags, custom_css: @custom_css,
            embedded: @embedded, template_dirs: @template_dirs
          }
        end

        def validate!
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
            sectnums: @config.section_numbering,
            sectnumlevels: @config.section_numbering_levels,
            toclevels: @config.toc_levels
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
