# frozen_string_literal: true

require 'nokogiri'
require 'liquid'
require_relative 'escape'
require_relative 'title_text'

module Coradoc
  module Html
    # Handles layout rendering for static and SPA HTML output.
    #
    # Renders the outer HTML shell (head, body wrapper, assets) around
    # the document body content. Falls back to Nokogiri::HTML::Builder
    # when layout templates are unavailable.
    class LayoutRenderer
      LAYOUT_DIR = Pathname.new(File.join(File.dirname(__FILE__), 'templates', 'layouts'))

      def initialize
        @template_cache = {}
        @dist_assets_cache = {}
      end

      def render_static(document, body_html, options)
        layout_template = load_layout('default')
        return build_static_fallback(document, body_html, options) unless layout_template

        layout_template.render(build_static_layout_data(document, body_html, options)).strip
      end

      def render_spa(document, options, content_data)
        dist_dir = options[:dist_dir] || File.expand_path('../../../frontend/dist', __dir__)
        assets = load_dist_assets(dist_dir)

        safe_json = Escape.safe_json(content_data)

        layout_template = load_layout('spa')
        if layout_template
          layout_template.render(build_spa_layout_data(document, options, assets, safe_json)).strip
        else
          build_spa_fallback(document, options, assets, safe_json)
        end
      end

      private

      def resolve_title(document)
        TitleText.resolve(document&.title) || 'Untitled'
      end

      def resolve_escaped_title(document)
        TitleText.escape(document&.title) || 'Untitled'
      end

      def build_static_layout_data(document, body_html, options)
        {
          'lang' => options[:lang] || 'en',
          'title' => resolve_escaped_title(document),
          'author' => options[:author],
          'description' => options[:description],
          'generator_version' => Coradoc::VERSION.to_s,
          'body' => body_html,
          'custom_css' => options[:custom_css]
        }
      end

      def build_static_fallback(document, body_html, options)
        lang = options[:lang] || 'en'
        Nokogiri::HTML::Builder.new do |doc|
          doc.html(lang: lang) do
            doc.head do
              doc.meta(charset: 'UTF-8')
              doc.meta(name: 'viewport', content: 'width=device-width, initial-scale=1.0')
              doc.title resolve_title(document)
            end
            doc.body { doc << body_html }
          end
        end.to_html
      end

      def build_spa_layout_data(document, options, assets, safe_json)
        {
          'lang' => options[:lang] || 'en',
          'title' => resolve_escaped_title(document),
          'author' => options[:author],
          'description' => options[:description],
          'generator_version' => Coradoc::VERSION.to_s,
          'css' => assets[:css],
          'js' => assets[:js],
          'data' => safe_json
        }
      end

      def build_spa_fallback(document, options, assets, safe_json)
        title = resolve_title(document)
        lang = options[:lang] || 'en'
        Nokogiri::HTML::Builder.new do |doc|
          doc.html(lang: lang) do
            doc.head do
              doc.meta(charset: 'UTF-8')
              doc.meta(name: 'viewport', content: 'width=device-width, initial-scale=1.0')
              doc.meta(name: 'generator', content: "Coradoc #{Coradoc::VERSION}")
              doc.title title
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
        return @template_cache[cache_key] if @template_cache.key?(cache_key)

        path = LAYOUT_DIR.join("#{name}.liquid")
        return nil unless path.exist?

        template_content = File.read(path)
        template = Liquid::Template.parse(template_content)
        @template_cache[cache_key] = template
        template
      rescue Liquid::SyntaxError => e
        warn "Layout template syntax error: #{e.message}"
        nil
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
