# frozen_string_literal: true

require 'nokogiri'

module Coradoc
  module Html
    module AssetResolver
      class << self
        def stylesheet_path(options = {})
          css_theme = options[:css_theme] || Config::DEFAULT_OPTIONS[:css_theme]
          stylesheet = "#{css_theme}.css"
          stylesdir = options[:stylesdir] || Config::DEFAULT_OPTIONS[:stylesdir]

          if stylesdir && stylesdir != '.'
            File.join(stylesdir, stylesheet)
          else
            stylesheet
          end
        end

        def embedded_stylesheet(options = {})
          css_theme = options[:css_theme] || Config::DEFAULT_OPTIONS[:css_theme]
          stylesheet_name = "#{css_theme}.css"

          themes_path = File.join(__dir__, 'assets', 'themes', stylesheet_name)
          asset_path = if File.exist?(themes_path)
                         themes_path
                       else
                         File.join(__dir__, 'assets', stylesheet_name)
                       end

          css_content = if File.exist?(asset_path)
                          File.read(asset_path)
                        else
                          default_path = File.join(__dir__, 'assets', 'coradoc.css')
                          File.exist?(default_path) ? File.read(default_path) : ''
                        end

          resolve_css_imports(css_content, File.dirname(asset_path))
        end

        def resolve_css_imports(css_content, base_dir)
          css_content.gsub(/@import\s+(?:url\()?['"]([^'"]+)['"]\)?;?/) do
            import_path = ::Regexp.last_match(1)
            full_path = File.join(base_dir, import_path)

            if File.exist?(full_path)
              imported_content = File.read(full_path)
              resolve_css_imports(imported_content, File.dirname(full_path))
            else
              ::Regexp.last_match(0)
            end
          end
        end

        def css_link_tag(options = {})
          href = stylesheet_path(options)
          doc = Nokogiri::HTML::Document.new
          node = Nokogiri::XML::Node.new('link', doc)
          node['rel'] = 'stylesheet'
          node['href'] = href
          node.to_html
        end

        def css_style_tag(options = {})
          css_content = embedded_stylesheet(options)
          custom_css = options[:custom_css]

          content = css_content
          content += "\n\n#{custom_css}" if custom_css && !custom_css.empty?

          build_text_element('style', content)
        end

        def custom_css_tag(custom_css)
          return '' unless custom_css && !custom_css.empty?

          build_text_element('style', custom_css)
        end

        def embed_css?(options = {})
          !options.fetch(:linkcss, Config::DEFAULT_OPTIONS[:linkcss]) ||
            options.fetch(:embedded, Config::DEFAULT_OPTIONS[:embedded])
        end

        def css_tags(options = {})
          tags = []

          if embed_css?(options)
            tags << css_style_tag(options)
          else
            tags << css_link_tag(options)
            tags << custom_css_tag(options[:custom_css]) if options[:custom_css]
          end

          tags.join("\n")
        end

        def embed_js?(options = {})
          !options.fetch(:linkjs, Config::DEFAULT_OPTIONS[:linkjs]) ||
            options.fetch(:embedded, Config::DEFAULT_OPTIONS[:embedded]) ||
            !options.fetch(:linkcss, Config::DEFAULT_OPTIONS[:linkcss])
        end

        def javascript_path(options = {})
          javascript = options[:javascript] || Config::DEFAULT_OPTIONS[:javascript]
          jsdir = options[:jsdir] || Config::DEFAULT_OPTIONS[:jsdir]

          if jsdir && jsdir != '.'
            File.join(jsdir, javascript)
          else
            javascript
          end
        end

        def embedded_javascript(options = {})
          javascript_name = options[:javascript] || Config::DEFAULT_OPTIONS[:javascript]
          asset_path = File.join(__dir__, 'assets', 'js', javascript_name)

          File.exist?(asset_path) ? File.read(asset_path) : ''
        end

        def js_link_tag(options = {})
          src = javascript_path(options)
          doc = Nokogiri::HTML::Document.new
          node = Nokogiri::XML::Node.new('script', doc)
          node['src'] = src
          node['defer'] = ''
          node.to_html
        end

        def js_script_tag(options = {})
          js_content = embedded_javascript(options)
          return '' if js_content.empty?

          build_text_element('script', js_content)
        end

        def js_tags(options = {})
          return '' if options[:javascript] == false

          tags = []

          tags << if embed_js?(options)
                    js_script_tag(options)
                  else
                    js_link_tag(options)
                  end

          tags.join("\n")
        end

        def syntax_highlighter_tags(options = {})
          highlighter = options[:source_highlighter]
          return '' unless highlighter

          case highlighter.to_sym
          when :highlightjs, :highlight_js, :'highlight.js'
            highlightjs_tags(options)
          else
            ''
          end
        end

        def highlightjs_tags(options = {})
          theme = options[:highlightjs_theme] || Config::DEFAULT_OPTIONS[:highlightjs_theme]
          doc = Nokogiri::HTML::Document.new

          link_node = Nokogiri::XML::Node.new('link', doc)
          link_node['rel'] = 'stylesheet'
          link_node['href'] = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/#{theme}.min.css"

          script_node = Nokogiri::XML::Node.new('script', doc)
          script_node['src'] = 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js'

          init_node = Nokogiri::XML::Node.new('script', doc)
          init_node.content = 'hljs.highlightAll();'

          [link_node.to_html, script_node.to_html, init_node.to_html].join("\n")
        end

        private

        def build_text_element(tag_name, content)
          doc = Nokogiri::HTML::Document.new
          node = Nokogiri::XML::Node.new(tag_name, doc)
          node.content = content
          node.to_html
        end
      end
    end
  end
end
