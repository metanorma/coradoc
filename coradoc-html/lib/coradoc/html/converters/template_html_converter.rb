# frozen_string_literal: true

require 'coradoc/html/template_renderer'

module Coradoc
  module Html
    module Converters
      # HTML converter that uses Liquid templates for rendering
      #
      # This converter provides template-based rendering where:
      # - Users can provide custom template directories
      # - Falls back to default templates
      # - Supports template inheritance
      #
      # @example Basic usage
      #   renderer = TemplateHtmlConverter.new(template_paths: ["/my/templates"])
      #   html = renderer.render(document)
      #
      class TemplateHtmlConverter < Base
        # Initialize the converter
        #
        # @param template_paths [Array<String>] Custom template directories
        # @param options [Hash] Additional options
        def initialize(template_paths: [], options: {})
          @template_paths = template_paths
          @options = options
          @renderer = nil
        end

        # Get or create the template renderer
        #
        # @return [Coradoc::Html::TemplateRenderer] The renderer
        def renderer
          @renderer ||= Coradoc::Html::TemplateRenderer.new(
            template_paths: @template_paths,
            options: @options
          )
        end

        # Render a CoreModel document to HTML
        #
        # @param model [Coradoc::CoreModel::Base] The document to render
        # @param state [Hash] Rendering state
        # @return [String] Rendered HTML
        def self.to_html(model, state = {})
          # Get template_paths from state or use defaults
          template_paths = state[:template_paths] || []

          # Create converter with template paths
          new(template_paths: template_paths, options: state[:template_options] || {})

          # Convert content using template renderer
          convert_content_to_html(model, state)
        end

        # Convert content to HTML using template renderer
        #
        # @param content [Object] Content to convert
        # @param state [Hash] Conversion state
        # @return [String] HTML string
        def self.convert_content_to_html(content, state = {})
          return '' if content.nil?

          renderer = Coradoc::Html::TemplateRenderer.new(
            template_paths: state[:template_paths] || [],
            options: state[:template_options] || {}
          )

          renderer.render(content)
        end

        # Render a CoreModel document to HTML using the template renderer
        #
        # @param model [Coradoc::CoreModel::Base] The document to render
        # @param state [Hash] Rendering state
        # @return [String] Rendered HTML
        def self.render_with_templates(model, state = {})
          renderer = Coradoc::Html::TemplateRenderer.new(
            template_paths: state[:template_paths] || [],
            options: state[:template_options] || {}
          )

          renderer.render(model)
        end
      end

      # Helper module for rendering CoreModel elements using templates
      module TemplateHelpers
        # Render a CoreModel element using templates
        #
        # @param element [Coradoc::CoreModel::Base] Element to render
        # @param template_paths [Array<String>] Custom template directories
        # @param options [Hash] Template options
        # @return [String] Rendered HTML
        def render_with_templates(element, template_paths: [], **options)
          renderer = Coradoc::Html::TemplateRenderer.new(
            template_paths: template_paths,
            options: options
          )
          renderer.render(element)
        end
      end
    end
  end
end
