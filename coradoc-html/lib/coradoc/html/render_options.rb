# frozen_string_literal: true

module Coradoc
  module Html
    class RenderOptions
      attr_reader :layout, :lang, :toc, :toc_levels, :section_numbers,
                  :section_number_levels, :author, :description, :custom_css,
                  :dist_dir, :theme_toggle, :reading_progress, :toc_placement

      def initialize(layout: :static, lang: 'en', toc: false, toc_levels: 2,
                     section_numbers: false, section_number_levels: 3,
                     author: nil, description: nil, custom_css: nil,
                     dist_dir: nil, theme_toggle: true, reading_progress: true,
                     toc_placement: :auto)
        @layout = layout
        @lang = lang
        @toc = toc
        @toc_levels = toc_levels
        @section_numbers = section_numbers
        @section_number_levels = section_number_levels
        @author = author
        @description = description
        @custom_css = custom_css
        @dist_dir = dist_dir
        @theme_toggle = theme_toggle
        @reading_progress = reading_progress
        @toc_placement = toc_placement
        freeze
      end

      def spa?
        @layout == :spa
      end

      def static?
        @layout == :static
      end
    end
  end
end
