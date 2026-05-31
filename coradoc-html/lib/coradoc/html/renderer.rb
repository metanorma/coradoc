# frozen_string_literal: true

require 'liquid'
require 'nokogiri'

module Coradoc
  module Html
    class Renderer
      DEFAULT_TEMPLATE_DIR = TemplateLocator::DEFAULT_TEMPLATE_DIR

      include TemplateCaching

      attr_reader :template_dirs, :options

      def initialize(template_dirs: nil, **options)
        @template_dirs = normalize_dirs(template_dirs)
        @options = options
        @template_cache = {}
        @locator = TemplateLocator.new(
          user_dirs: @template_dirs,
          default_dir: DEFAULT_TEMPLATE_DIR
        )
        @section_numbers = {}
        @layout_renderer = LayoutRenderer.new
      end

      def render(element)
        result = Drop::DropFactory.create(element)
        case result
        when Drop::Base then render_drop(result)
        when Array then result.map { |r| r.is_a?(Drop::Base) ? render_drop(r) : r }.join("\n")
        when nil then ''
        else result
        end
      end

      def render_drop(drop)
        return '' if drop.nil?
        return drop.to_s unless drop.is_a?(Drop::Base)

        annotate_section_number(drop)

        template_type = drop.template_type
        template = find_and_load_template(template_type)
        return render_fallback_drop(drop) unless template

        assigns = { 'element' => drop }
        template.render(assigns, registers: { renderer: self, section_numbers: @section_numbers }).strip
      end

      def render_html5(document, **options)
        @section_numbers = compute_section_numbers(document, options)
        body_html = render(document)

        if options[:layout] == :spa
          render_spa_layout(document, body_html, options)
        else
          render_static_layout(document, body_html, options)
        end
      end

      def available_templates
        @locator.available_templates
      end

      def template_exists?(type_name)
        @locator.exists?(type_name)
      end

      def find_template(type_name)
        find_and_load_template(type_name)
      end

      private

      def build_toc(_document, options)
        TocBuilder.from_options(options)
      end

      def compute_section_numbers(document, options)
        if options[:section_numbers] && document.is_a?(CoreModel::StructuralElement)
          build_toc(document, options).section_number_map(document)
        else
          {}
        end
      end

      def render_toc_for(document, options)
        toc = build_toc(document, options).build(document)
        render(toc)
      end

      def render_static_layout(document, body_html, options)
        if options[:toc] && document.is_a?(CoreModel::StructuralElement)
          toc_html = render_toc_for(document, options)
          body_html = "#{toc_html}\n#{body_html}" unless toc_html.empty?
        end
        @layout_renderer.render_static(document, body_html, options)
      end

      def render_spa_layout(document, body_html, options)
        toc_data = TocSerializer.new.build_json(document, options)
        @layout_renderer.render_spa(document, options, body_html, toc_data)
      end

      def find_and_load_template(type_name)
        cache_key = type_name.to_s
        path = @locator.find(type_name)
        load_template(cache: @template_cache, cache_key: cache_key, path: path)
      end

      def annotate_section_number(drop)
        return unless drop.is_a?(SectionNumberable)
        return if @section_numbers.empty?

        id = drop.id
        number = @section_numbers[id]
        drop.section_number = number if number
      end

      def render_fallback_drop(drop)
        type = drop.template_type
        resolved = TitleText.resolve(drop.model)
        text = resolved ? Escape.escape_html(resolved) : ''

        doc = Nokogiri::HTML::Document.new
        fragment = Nokogiri::HTML::Builder.with(doc) do |builder|
          builder.div(class: "element element-#{type}") { builder.text text }
        end
        fragment.at_css('div').to_html
      end

      def normalize_dirs(dirs)
        return [] if dirs.nil?

        Array(dirs).map do |dir|
          path = Pathname.new(dir)
          path.absolute? ? path.to_s : File.expand_path(dir)
        end
      end
    end
  end
end
