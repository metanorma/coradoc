# frozen_string_literal: true

require 'coradoc/html'
require 'coradoc/html/config'
require 'coradoc/html/converters/base'

module Coradoc
  module Html
    module Theme
      # Classic theme renderer
      #
      # This renderer wraps the existing Coradoc HTML generation system.
      # It maintains backward compatibility with the classic theme while
      # following the new theme system architecture.
      #
      # The classic theme is the default theme and provides the same output
      # as the original Coradoc HTML converter.
      class ClassicRenderer < Base
        # Register this theme automatically
        Registry.auto_register(self)

        # Check if template rendering is enabled
        #
        # @return [Boolean]
        def use_templates?
          @options[:use_templates] == true
        end

        # Get the template renderer when templates are enabled
        #
        # @return [Coradoc::Html::Renderer, nil]
        def template_renderer
          return nil unless use_templates?

          @template_renderer ||= begin
            dirs = @options[:template_dirs] || global_template_dirs
            Renderer.new(template_dirs: dirs)
          end
        end

        # Supported features for classic theme
        #
        # @return [Array<Symbol>] Supported features
        def supported_features
          features = %i[
            dark_mode
            theme_toggle
            syntax_highlighting
            table_of_contents
            section_numbering
          ]
          features << :template_rendering if use_templates?
          features
        end

        # Render document to HTML
        #
        # Generates HTML body content from the document.
        # Uses the HTML Converters directly to avoid circular dependency.
        # When templates are enabled, uses the template renderer instead.
        #
        # @return [String] HTML string
        def render
          return template_renderer.render(@document) if use_templates? && template_renderer

          # Use HTML converters directly to convert document model to HTML
          # This avoids circular dependency with Coradoc::Output::Html
          Coradoc::Html::Converters::Document.to_html(@document, @options)
        end

        # Render complete HTML5 document
        #
        # Builds the complete HTML5 document with head, body, and all assets.
        # @return [String] Complete HTML5 document
        def render_html5
          html_body = render

          lang = @options[:lang] || 'en'
          body_classes = build_body_classes

          # Apply section numbering if enabled
          final_body = if @options[:sectnums]
                         apply_section_numbering(html_body)
                       else
                         html_body
                       end

          # Build TOC if enabled
          toc_html = build_toc

          # Insert TOC based on placement
          final_body = insert_toc(final_body, toc_html)

          # Add theme toggle button if enabled
          theme_button = build_theme_toggle_button

          <<~HTML
            <!DOCTYPE html>
            <html lang="#{lang}">
            <head>
            #{build_head_content}
            </head>
            <body#{body_classes}>
            #{final_body}
            #{theme_button}
            </body>
            </html>
          HTML
        end

        protected

        # Get global template directories from configuration
        def global_template_dirs
          Coradoc::Html.configuration.template_dirs.map(&:to_s)
        end

        # Build body classes
        #
        # @return [String] Body class attribute
        def build_body_classes
          classes = []

          # Add TOC placement class
          if @options[:toc]
            placement = @options[:toc_placement] || :auto
            classes << "toc-#{placement}" unless placement == :auto
          end

          classes.empty? ? '' : %( class="#{classes.join(' ')}")
        end

        # Build CSS tags
        #
        # @return [String] CSS link or style tags
        def build_css_tags
          Coradoc::Html::Config.css_tags(@options).split("\n")
                               .map { |line| "  #{line}" }.join("\n")
        end

        # Build script tags
        #
        # @return [String] Script tags
        def build_script_tags
          js = Coradoc::Html::Config.js_tags(@options)
          return '' if js.empty?

          js.split("\n").map { |line| "  #{line}" }.join("\n")
        end

        # Build syntax highlighter tags
        #
        # @return [String] Syntax highlighter tags HTML
        def build_head_content
          parts = []
          parts << build_meta_tags
          parts << build_title_tag
          parts << build_css_tags
          parts << build_script_tags
          parts << build_syntax_highlighter_tags
          parts.compact.reject(&:empty?).join("\n")
        end

        # Build syntax highlighter tags
        #
        # @return [String] Syntax highlighter tags HTML
        def build_syntax_highlighter_tags
          tags = Coradoc::Html::Config.syntax_highlighter_tags(@options)
          return '' if tags.empty?

          tags.split("\n").map { |line| "  #{line}" }.join("\n")
        end

        # Insert TOC into body HTML based on placement
        #
        # @param body_html [String] Body HTML content
        # @param toc_html [String] TOC HTML
        # @return [String] Combined HTML
        def insert_toc(body_html, toc_html)
          return body_html if toc_html.empty?

          placement = @options[:toc_placement] || :auto

          case placement
          when :left, :right
            # For sidebar placements, TOC is positioned via CSS
            "#{toc_html}\n#{body_html}"
          when :auto, :preamble
            # Insert after header, before main content
            if body_html =~ %r{(</h1>)}
              body_html.sub(::Regexp.last_match(1), "#{::Regexp.last_match(1)}\n#{toc_html}")
            else
              "#{toc_html}\n#{body_html}"
            end
          else
            # Default: prepend to body
            "#{toc_html}\n#{body_html}"
          end
        end

        # Build theme toggle button HTML
        #
        # @return [String] Theme toggle button HTML or empty string
        def build_theme_toggle_button
          return '' unless @options[:theme_toggle]

          <<~HTML
            <button id="theme-toggle" aria-label="Toggle dark mode" title="Toggle dark/light mode">
              <span class="theme-toggle-icon">☀️</span>
            </button>
          HTML
        end

        # Build table of contents
        #
        # @return [String] TOC HTML or empty string
        def build_toc
          return '' unless @options[:toc]

          toc_placement = @options[:toc_placement] || :auto
          toc_class = toc_placement == :auto ? 'toc' : "toc toc-#{toc_placement}"

          sections = extract_sections(@document)
          return '' if sections.empty?

          toc_title = @options[:toc_title] || 'Table of Contents'
          toc_levels = @options[:toclevels] || 2

          build_toc_html(sections, toc_levels, toc_class, toc_title)
        end

        # Extract sections from document
        #
        # @param doc [Coradoc::CoreModel::StructuralElement] Document to extract sections from
        # @return [Array] Array of section objects
        def extract_sections(doc)
          sections = []
          return sections unless doc.respond_to?(:sections)

          collect_sections(doc.sections, sections, 1)
          sections
        end

        # Recursively collect sections
        #
        # @param items [Array] Items to process
        # @param sections [Array] Accumulated sections
        # @param level [Integer] Current section level
        def collect_sections(items, sections, level)
          return unless items

          items.each do |item|
            next unless item.is_a?(Coradoc::CoreModel::StructuralElement)

            section_data = {
              title: extract_section_title(item),
              id: extract_section_id(item),
              level: level,
              children: []
            }

            # Recursively collect subsections
            if item.respond_to?(:sections) && item.sections
              collect_sections(item.sections, section_data[:children],
                               level + 1)
            end

            sections << section_data
          end
        end

        # Extract section title
        #
        # @param section [Coradoc::CoreModel::StructuralElement] Section to extract title from
        # @return [String] Section title
        def extract_section_title(section)
          if section.respond_to?(:title)
            title = section.title
            if title.respond_to?(:text)
              title.text
            elsif title.respond_to?(:content)
              Coradoc::Html::Converters::Base.get_text_content(title)
            elsif title.is_a?(Array)
              title.map { |t| t.respond_to?(:text) ? t.text : t.to_s }.join
            else
              title.to_s
            end
          else
            'Untitled Section'
          end
        end

        # Extract section ID
        #
        # @param section [Coradoc::CoreModel::StructuralElement] Section to extract ID from
        # @return [String] Section ID
        def extract_section_id(section)
          if section.respond_to?(:id) && section.id
            section.id
          else
            # Generate ID from title
            title = extract_section_title(section)
            "_#{title.to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_+|_+$/, '')}"
          end
        end

        # Build TOC HTML
        #
        # @param sections [Array] Section data
        # @param max_level [Integer] Maximum level to include
        # @param toc_class [String] CSS class for TOC
        # @param toc_title [String] TOC title
        # @return [String] TOC HTML
        def build_toc_html(sections, max_level, toc_class, toc_title)
          return '' if sections.empty?

          html = []
          html << %(<div id="toc" class="#{toc_class}">)
          html << %(  <div class="toc-title">#{escape_html(toc_title)}</div>)
          html << build_toc_list(sections, 1, max_level)
          html << %(</div>)
          html.join("\n")
        end

        # Build TOC list recursively
        #
        # @param sections [Array] Section data
        # @param current_level [Integer] Current level
        # @param max_level [Integer] Maximum level
        # @return [String] List HTML
        def build_toc_list(sections, current_level, max_level)
          return '' if sections.empty? || current_level > max_level

          html = []
          html << %(  <ul class="sectlevel#{current_level}">)

          sections.each do |section|
            html << %(    <li>)
            html << %(      <a href="##{section[:id]}">#{escape_html(section[:title])}</a>)

            # Add nested list for children
            if section[:children] && !section[:children].empty? && current_level < max_level
              nested_html = build_toc_list(section[:children], current_level + 1, max_level)
              html << nested_html if nested_html && !nested_html.empty?
            end

            html << %(    </li>)
          end

          html << %(  </ul>)
          html.join("\n")
        end

        # Apply section numbering to HTML
        #
        # @param html [String] HTML content
        # @return [String] HTML with section numbers
        def apply_section_numbering(html)
          require 'nokogiri'

          max_level = @options[:sectnumlevels] || 3
          doc = Nokogiri::HTML::DocumentFragment.parse(html)

          # Track section numbers at each level
          counters = Array.new(max_level + 1, 0)

          # Find all headings (h2-h6, h1 is document title)
          (2..6).each do |level|
            doc.css("h#{level}").each do |heading|
              section_level = level - 1 # h2 = level 1, h3 = level 2, etc.
              next if section_level > max_level

              # Increment counter for this level
              counters[section_level] += 1

              # Reset deeper level counters
              ((section_level + 1)..max_level).each { |i| counters[i] = 0 }

              # Build section number (e.g., "1.2.3")
              section_number = counters[1..section_level].join('.')

              # Add section number to heading
              number_span = %(<span class="sectnum">#{section_number}. </span>)
              heading.inner_html = number_span + heading.inner_html
            end
          end

          doc.to_html
        end
      end
    end
  end
end
