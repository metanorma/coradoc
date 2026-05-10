# frozen_string_literal: true

require 'coradoc/html'
require 'coradoc/html/config'
require 'coradoc/html/converters/base'
require 'coradoc/html/node_builder'

module Coradoc
  module Html
    module Theme
      class ClassicRenderer < Base
        Registry.auto_register(self)

        def use_templates?
          @options[:use_templates] == true
        end

        def template_renderer
          return nil unless use_templates?

          @template_renderer ||= begin
            dirs = @options[:template_dirs] || global_template_dirs
            Renderer.new(template_dirs: dirs)
          end
        end

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

        def render
          return template_renderer.render(@document) if use_templates? && template_renderer

          Coradoc::Html::Converters::Document.to_html(@document, @options)
        end

        def render_html5
          html_body = render

          lang = @options[:lang] || 'en'
          body_classes = build_body_classes

          final_body = html_body
          final_body = if @options[:sectnums]
                         apply_section_numbering(final_body)
                       else
                         final_body
                       end

          toc_html = build_toc
          final_body = insert_toc(final_body, toc_html)
          theme_button = build_theme_toggle_button

          build_html5_document(final_body, theme_button, lang, body_classes)
        end

        protected

        def global_template_dirs
          Coradoc::Html.configuration.template_dirs.map(&:to_s)
        end

        def build_body_classes
          classes = []
          if @options[:toc]
            placement = @options[:toc_placement] || :auto
            classes << "toc-#{placement}" unless placement == :auto
          end
          classes.empty? ? '' : %( class="#{classes.join(' ')}")
        end

        def build_css_tags
          Coradoc::Html::Config.css_tags(@options).split("\n")
                               .map { |line| "  #{line}" }.join("\n")
        end

        def build_script_tags
          js = Coradoc::Html::Config.js_tags(@options)
          return '' if js.empty?

          js.split("\n").map { |line| "  #{line}" }.join("\n")
        end

        def build_head_content
          parts = []
          parts << build_meta_tags
          parts << build_title_tag
          parts << build_css_tags
          parts << build_script_tags
          parts << build_syntax_highlighter_tags
          parts.compact.reject(&:empty?).join("\n")
        end

        def build_syntax_highlighter_tags
          tags = Coradoc::Html::Config.syntax_highlighter_tags(@options)
          return '' if tags.empty?

          tags.split("\n").map { |line| "  #{line}" }.join("\n")
        end

        def insert_toc(body_html, toc_html)
          return body_html if toc_html.empty?

          placement = @options[:toc_placement] || :auto

          case placement
          when :left, :right
            "#{toc_html}\n#{body_html}"
          when :auto, :preamble
            if body_html =~ %r{(</h1>)}
              body_html.sub(::Regexp.last_match(1), "#{::Regexp.last_match(1)}\n#{toc_html}")
            else
              "#{toc_html}\n#{body_html}"
            end
          else
            "#{toc_html}\n#{body_html}"
          end
        end

        def build_theme_toggle_button
          return '' unless @options[:theme_toggle]

          span = NodeBuilder.build(:span, nil, class: 'theme-toggle-icon')
          span.inner_html = '&#x2600;'
          NodeBuilder.build(:button, span, id: 'theme-toggle',
                                           'aria-label' => 'Toggle dark mode',
                                           title: 'Toggle dark/light mode').to_html
        end

        def build_toc
          return '' unless @options[:toc]

          sections = extract_sections(@document)
          return '' if sections.empty?

          toc_placement = @options[:toc_placement] || :auto
          toc_class = toc_placement == :auto ? 'toc' : "toc toc-#{toc_placement}"
          toc_title = @options[:toc_title] || 'Table of Contents'
          toc_levels = @options[:toclevels] || 2

          build_toc_html(sections, toc_levels, toc_class, toc_title)
        end

        def extract_sections(doc)
          sections = []
          return sections unless doc.is_a?(Coradoc::CoreModel::StructuralElement)

          collect_sections(doc.children, sections, 1)
          sections
        end

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
            collect_sections(item.children, section_data[:children], level + 1)
            sections << section_data
          end
        end

        def extract_section_title(section)
          title = section.title
          if title
            if title.is_a?(Coradoc::CoreModel::Base) && title.text
              title.text
            elsif title.is_a?(Coradoc::CoreModel::Base) && title.content
              Coradoc::Html::Converters::Base.get_text_content(title)
            elsif title.is_a?(Array)
              title.map { |t| t.is_a?(Coradoc::CoreModel::Base) && t.text ? t.text : t.to_s }.join
            else
              title.to_s
            end
          else
            'Untitled Section'
          end
        end

        def extract_section_id(section)
          section.id || begin
            title = extract_section_title(section)
            "_#{title.to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_+|_+$/, '')}"
          end
        end

        def build_toc_html(sections, max_level, toc_class, toc_title)
          return '' if sections.empty?

          title_div = NodeBuilder.build(:div, escape_html(toc_title), class: 'toc-title')
          list_html = build_toc_list(sections, 1, max_level)
          NodeBuilder.build(:div, [title_div, list_html], id: 'toc', class: toc_class).to_html
        end

        def build_toc_list(sections, current_level, max_level)
          return '' if sections.empty? || current_level > max_level

          items = sections.map do |section|
            link = NodeBuilder.build(:a, escape_html(section[:title]), href: "##{section[:id]}")
            li_children = [link]
            if section[:children] && !section[:children].empty? && current_level < max_level
              nested = build_toc_list(section[:children], current_level + 1, max_level)
              li_children << nested unless nested.empty?
            end
            NodeBuilder.build(:li, li_children)
          end

          NodeBuilder.build(:ul, items, class: "sectlevel#{current_level}").to_html
        end

        def apply_section_numbering(html)
          max_level = @options[:sectnumlevels] || 3
          doc = Nokogiri::HTML::DocumentFragment.parse(html)
          counters = Array.new(max_level + 1, 0)

          doc.traverse do |node|
            next unless node.element?
            next unless node.name =~ /\Ah(\d)\z/

            level = ::Regexp.last_match(1).to_i
            next if level < 2

            section_level = level - 1
            next if section_level > max_level

            counters[section_level] += 1
            ((section_level + 1)..max_level).each { |i| counters[i] = 0 }

            section_number = counters[1..section_level].join('.')
            number_span = NodeBuilder.build(:span, "#{section_number}. ", class: 'sectnum')
            node.prepend_child(number_span)
          end

          doc.to_html
        end

        private

        def build_html5_document(body_html, theme_button, lang, body_classes)
          html = []
          html << '<!DOCTYPE html>'
          html << "<html lang=\"#{lang}\">"
          html << '<head>'
          head_content = build_head_content
          html << head_content unless head_content.empty?
          html << '</head>'
          html << "<body#{body_classes}>"
          html << body_html
          html << theme_button unless theme_button.empty?
          html << '</body>'
          html << '</html>'
          html.join("\n")
        end

        def escape_html(text)
          Coradoc::Html::Base.escape_html(text)
        end
      end
    end
  end
end
