# frozen_string_literal: true

require 'coradoc/html/base'

module Coradoc
  module Html
    module Theme
      # Abstract base class for all HTML themes
      #
      # This class defines the interface that all theme renderers must implement.
      # Themes are responsible for converting Coradoc document models to HTML output.
      #
      # @abstract Subclass and implement {#render} to create a custom theme
      class Base
        attr_reader :document, :options

        # Initialize a new theme instance
        #
        # @param document [Coradoc::CoreModel::StructuralElement] The document to render
        # @param options [Hash] Rendering options
        def initialize(document, options = {})
          @document = document
          @options = options
        end

        # Render the document to HTML
        #
        # This method must be implemented by subclasses.
        #
        # @abstract
        # @return [String] The rendered HTML content
        def render
          raise NotImplementedError,
                "#{self.class.name} must implement #render method"
        end

        # Render the complete HTML5 document
        #
        # @return [String] Complete HTML5 document
        def render_html5
          html_body = render
          build_html5_document(html_body)
        end

        # Get the theme name
        #
        # @return [Symbol] Theme name (e.g., :classic, :modern)
        def theme_name
          @theme_name ||= self.class.name.split('::').last
                              .gsub(/Renderer$/, '')
                              .downcase
                              .to_sym
        end

        # Check if this theme supports a specific feature
        #
        # @param feature [Symbol] Feature to check (e.g., :dark_mode, :interactive_toc)
        # @return [Boolean] true if the feature is supported
        def supports?(feature)
          supported_features.include?(feature)
        end

        # List of features supported by this theme
        #
        # Subclasses can override to declare supported features.
        #
        # @return [Array<Symbol>] List of supported features
        def supported_features
          []
        end

        protected

        # Build complete HTML5 document
        #
        # @param body_html [String] HTML body content
        # @return [String] Complete HTML5 document
        def build_html5_document(body_html)
          lang = @options[:lang] || 'en'
          body_classes = build_body_classes

          <<~HTML
            <!DOCTYPE html>
            <html lang="#{lang}">
            <head>
            #{build_head_content}
            </head>
            <body#{body_classes}>
            #{body_html}
            </body>
            </html>
          HTML
        end

        # Build HTML head content
        #
        # @return [String] Head section HTML
        def build_head_content
          parts = []
          parts << build_meta_tags
          parts << build_title_tag
          parts << build_css_tags
          parts << build_script_tags
          parts.compact.reject(&:empty?).join("\n")
        end

        # Build meta tags
        #
        # @return [String] Meta tags HTML
        def build_meta_tags
          meta = []
          meta << '  <meta charset="UTF-8">'
          meta << '  <meta name="viewport" content="width=device-width, initial-scale=1.0">'

          # Author meta tag
          if @options[:author]
            author = escape_attr(@options[:author])
            meta << %(  <meta name="author" content="#{author}">)
          end

          # Description meta tag
          if @options[:description]
            description = escape_attr(@options[:description])
            meta << %(  <meta name="description" content="#{description}">)
          end

          # Keywords meta tag
          if @options[:keywords]
            keywords = escape_attr(@options[:keywords])
            meta << %(  <meta name="keywords" content="#{keywords}">)
          end

          # Generator meta tag with version
          meta << %(  <meta name="generator" content="Coradoc #{Coradoc::VERSION}">)

          # Generation timestamp
          meta << %(  <meta name="generated" content="#{Time.now.utc.iso8601}">)

          # Custom meta tags
          if @options[:meta_tags].is_a?(Hash)
            @options[:meta_tags].each do |name, content|
              meta << %(  <meta name="#{escape_attr(name)}" content="#{escape_attr(content)}">)
            end
          end

          meta.join("\n")
        end

        # Build title tag
        #
        # @return [String] Title tag HTML
        def build_title_tag
          title = extract_document_title
          "  <title>#{escape_html(title)}</title>"
        end

        # Extract document title
        #
        # @return [String] Document title
        def extract_document_title
          # Handle CoreModel::StructuralElement (has title directly)
          if @document.respond_to?(:title) && @document.title
            title = @document.title
            return title if title.is_a?(String)
            return title.text if title.respond_to?(:text)

            return title.to_s
          end

          'Untitled Document'
        end

        # Extract text from content (array of inline elements)
        #
        # @param content [Array] Content elements
        # @return [String] Extracted text
        def extract_text_from_content(content)
          case content
          when Array
            content.map { |item| extract_text_from_content(item) }.join
          when String
            content
          when Coradoc::CoreModel::InlineElement
            content.text
          else
            content.to_s
          end
        end

        # Build body classes
        #
        # @return [String] Body class attribute
        def build_body_classes
          classes = []
          classes << "theme-#{theme_name}"

          classes.empty? ? '' : %( class="#{classes.join(' ')}")
        end

        # Build CSS tags
        #
        # @return [String] CSS link or style tags
        def build_css_tags
          ''
        end

        # Build script tags
        #
        # @return [String] Script tags
        def build_script_tags
          ''
        end

        # Escape HTML content
        #
        # @param text [String] Text to escape
        # @return [String] Escaped text
        def escape_html(text)
          Coradoc::Html::Base.escape_html(text.to_s)
        end

        # Escape HTML attribute value
        #
        # @param value [String] Value to escape
        # @return [String] Escaped value
        def escape_attr(value)
          value.to_s.gsub('"', '&quot;').gsub('<', '&lt;').gsub('>', '&gt;')
        end
      end
    end
  end
end
