# frozen_string_literal: true

require 'nokogiri'
require 'liquid'

module Coradoc
  module Html
    class LayoutRenderer
      include TemplateCaching

      LAYOUT_DIR = Pathname.new(File.join(File.dirname(__FILE__), 'templates', 'layouts'))

      def initialize
        @template_cache = {}
        @dist_assets_cache = {}
      end

      def render_static(document, body_html, opts)
        opts = RenderOptions.new(**opts) unless opts.is_a?(RenderOptions)
        layout_template = load_layout('default')
        return build_static_fallback(document, body_html, opts) unless layout_template

        layout_template.render(build_static_layout_data(document, body_html, opts)).strip
      end

      def render_spa(document, opts, body_html, toc_data)
        opts = RenderOptions.new(**opts) unless opts.is_a?(RenderOptions)
        dist_dir = opts.dist_dir || File.expand_path('../../../frontend/dist', __dir__)
        assets = load_dist_assets(dist_dir)

        content_data = build_spa_content_data(document, body_html, opts, toc_data)
        safe_json = Escape.safe_json(content_data)

        layout_template = load_layout('spa')
        if layout_template
          layout_template.render(build_spa_layout_data(document, opts, assets, safe_json)).strip
        else
          build_spa_fallback(document, opts, assets, safe_json)
        end
      end

      private

      def resolve_title(document)
        TitleText.resolve(document&.title) || Config::DEFAULT_TITLE
      end

      def resolve_escaped_title(document)
        TitleText.escape(document&.title) || Config::DEFAULT_TITLE
      end

      def resolve_lang(opts)
        opts.lang || Config::DEFAULT_LANG
      end

      def build_static_layout_data(document, body_html, opts)
        {
          'lang' => resolve_lang(opts),
          'title' => resolve_escaped_title(document),
          'author' => opts.author,
          'description' => opts.description,
          'generator_version' => Coradoc::VERSION.to_s,
          'body' => body_html,
          'custom_css' => opts.custom_css
        }
      end

      def build_static_fallback(document, body_html, opts)
        Nokogiri::HTML::Builder.new do |doc|
          doc.html(lang: resolve_lang(opts)) do
            doc.head do
              doc.meta(charset: 'UTF-8')
              doc.meta(name: 'viewport', content: 'width=device-width, initial-scale=1.0')
              doc.title resolve_title(document)
            end
            doc.body { doc << body_html }
          end
        end.to_html
      end

      def build_spa_content_data(document, body_html, opts, toc_data)
        {
          mode: 'classic',
          contentHtml: body_html,
          toc: toc_data,
          meta: build_spa_meta(document, opts),
          options: build_spa_options(opts)
        }
      end

      def build_spa_meta(document, _opts)
        {
          title: TitleText.resolve(document&.title) || Config::DEFAULT_TITLE,
          author: _opts.author,
          date: nil,
          generator: "Coradoc #{Coradoc::VERSION}"
        }
      end

      def build_spa_options(opts)
        {
          toc: opts.toc ? true : false,
          tocPlacement: (opts.toc_placement || :auto).to_s,
          sectnums: opts.section_numbers == true,
          themeToggle: opts.theme_toggle != false,
          readingProgress: opts.reading_progress != false,
          lang: resolve_lang(opts)
        }
      end

      def build_spa_layout_data(document, opts, assets, safe_json)
        {
          'lang' => resolve_lang(opts),
          'title' => resolve_escaped_title(document),
          'author' => opts.author,
          'description' => opts.description,
          'generator_version' => Coradoc::VERSION.to_s,
          'css' => assets[:css],
          'js' => assets[:js],
          'data' => safe_json
        }
      end

      def build_spa_fallback(document, opts, assets, safe_json)
        Nokogiri::HTML::Builder.new do |doc|
          doc.html(lang: resolve_lang(opts)) do
            doc.head do
              doc.meta(charset: 'UTF-8')
              doc.meta(name: 'viewport', content: 'width=device-width, initial-scale=1.0')
              doc.meta(name: 'generator', content: "Coradoc #{Coradoc::VERSION}")
              doc.title resolve_title(document)
              doc.style { doc.text assets[:css] } if assets[:css]
            end
            doc.body do
              doc.div(id: 'coradoc-app')
              doc.script { doc << "window.CORADOC_DATA = #{safe_json};" }
              doc.script { doc << assets[:js] } if assets[:js]
            end
          end
        end.to_html
      end

      def load_layout(name)
        cache_key = "layout:#{name}"
        path = LAYOUT_DIR.join("#{name}.liquid").to_s
        load_template(cache: @template_cache, cache_key: cache_key, path: path)
      end

      def load_dist_assets(dist_dir)
        @dist_assets_cache[dist_dir] ||= begin
          unless File.directory?(dist_dir)
            raise ArgumentError,
                  "Frontend dist directory not found: #{dist_dir}. " \
                  'Build the frontend first: cd frontend && npm install && npm run build'
          end

          {
            css: File.read(File.join(dist_dir, 'app.css')),
            js: File.read(File.join(dist_dir, 'app.iife.js'))
          }
        end
      end
    end
  end
end
