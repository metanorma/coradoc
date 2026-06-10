# frozen_string_literal: true

module Coradoc
  module Html
    HTML_EXTENSIONS = %w[.html .htm].freeze

    module FormatDetection
      def html_extension?(filename)
        HTML_EXTENSIONS.any? { |ext| filename.downcase.end_with?(ext) }
      end
    end
  end
end

# Load HTML input module to register with Coradoc::Input
require 'coradoc/html/input'
# Load HTML output module to register with Coradoc::Output
require 'coradoc/html/output'

module Coradoc
  module Html
    # Autoload HTML components
    autoload :Config, 'coradoc/html/config'
    autoload :AssetResolver, 'coradoc/html/asset_resolver'
    autoload :TagMapping, 'coradoc/html/tag_mapping'
    autoload :Escape, 'coradoc/html/escape'
    autoload :SectionNumberable, 'coradoc/html/section_numberable'
    autoload :TemplateCaching, 'coradoc/html/template_caching'
    autoload :TitleText, 'coradoc/html/title_text'

    # Drop layer — self-registering drops loaded via parent namespace file
    require 'coradoc/html/drop'

    # Autoload HTML output converters
    autoload :ConverterBase, 'coradoc/html/converter_base'
    autoload :Static, 'coradoc/html/static'
    autoload :Spa, 'coradoc/html/spa'
    autoload :TocBuilder, 'coradoc/html/toc_builder'

    # Theme system
    autoload :Theme, 'coradoc/html/theme'
    autoload :TemplateLocator, 'coradoc/html/template_locator'
    autoload :TemplateConfig, 'coradoc/html/template_config'
    # Side-effect: registers Liquid filters on load
    require 'coradoc/html/template_helpers'
    autoload :Renderer, 'coradoc/html/renderer'
    autoload :LayoutRenderer, 'coradoc/html/layout_renderer'
    autoload :RenderOptions, 'coradoc/html/render_options'
    autoload :TocSerializer, 'coradoc/html/toc_serializer'

    # CoreModel transformers
    module Transform
      autoload :ToCoreModel, 'coradoc/html/transform/to_core_model'
      autoload :FromCoreModel, 'coradoc/html/transform/from_core_model'
    end

    # Validate that input is a CoreModel type
    #
    # @param document [Object] Document to validate
    # @raise [ArgumentError] If document is not a CoreModel type
    # @return [Object] The validated document
    def self.validate_core_model!(document)
      return document if document.nil?

      unless document.is_a?(Coradoc::CoreModel::Base)
        raise ArgumentError,
              'coradoc-html only accepts CoreModel types. ' \
              "Got: #{document.class}. " \
              'Transform your document to CoreModel before passing to HTML conversion.'
      end

      document
    end

    # Parse HTML content and return CoreModel elements (may be an Array)
    def self.parse(html, options = {})
      ::Coradoc::Input::Html.to_coradoc(html, options)
    end

    # Parse HTML content directly into a CoreModel document
    #
    # Unlike #parse which returns an Array of CoreModel elements,
    # this wraps the result into a top-level DocumentElement document
    # suitable for use with Coradoc.serialize and other CoreModel pipelines.
    #
    # @param html [String] HTML content
    # @param options [Hash] Parse options
    # @return [Coradoc::CoreModel::DocumentElement] CoreModel document
    def self.parse_to_core(html, options = {})
      elements = parse(html, options)

      return elements if elements.is_a?(Coradoc::CoreModel::Base)

      # Extract document title from the first heading element
      title = nil
      children = elements
      if elements.is_a?(Array) && !elements.empty?
        first = elements.first
        if first.is_a?(Coradoc::CoreModel::StructuralElement) &&
           first.section? && first.level == 1
          title = first.title
          children = first.children + elements[1..]
        end
      end

      Coradoc::CoreModel::DocumentElement.new(
        title: title,
        children: Array(children)
      )
    end

    # Parse HTML file
    def self.from_file(filename, **)
      content = File.read(filename)
      parse(content, **)
    end

    # Serialize CoreModel document to HTML
    #
    # Uses the unified Liquid template renderer.
    #
    # @param document [Coradoc::CoreModel::Base] CoreModel document to serialize
    # @param options [Hash] Output options
    # @return [String] HTML output
    def self.serialize(document, options = {})
      validate_core_model!(document)

      layout = options.delete(:layout) || :static
      renderer = Renderer.new(template_dirs: options.delete(:template_dirs))
      renderer.render_html5(document, layout: layout, **options)
    end

    # Serialize CoreModel document to static HTML
    #
    # Uses the classic theme renderer for traditional HTML output.
    #
    # @param document [Coradoc::CoreModel::Base] CoreModel document to serialize
    # @param config [Hash, Static::Configuration] Static converter configuration
    # @return [String] HTML output
    def self.serialize_static(document, config = {})
      Static.convert(document, config)
    end

    # Serialize CoreModel document to SPA HTML
    #
    # Uses the modern theme renderer for Vue.js + Tailwind output.
    #
    # @param document [Coradoc::CoreModel::Base] CoreModel document to serialize
    # @param config [Hash, Spa::Configuration] SPA converter configuration
    # @return [String] HTML output
    def self.serialize_spa(document, config = {})
      Spa.convert(document, config)
    end

    # Serialize CoreModel document to HTML with specified format
    #
    # @param document [Coradoc::CoreModel::Base] CoreModel document to serialize
    # @param format [Symbol] Output format (:static, :spa, :classic)
    # @param options [Hash] Converter options
    # @return [String] HTML output
    def self.serialize_as(document, format, options = {})
      case format.to_sym
      when :static, :html_static, :classic
        serialize_static(document, options)
      when :spa, :html_spa, :modern
        serialize_spa(document, options)
      else
        raise ArgumentError, "Unknown output format: #{format}. " \
                             'Valid formats: :static, :spa'
      end
    end

    # Transform HTML model to CoreModel
    #
    # @param document [Object] HTML input model
    # @return [Coradoc::CoreModel::Base] CoreModel document
    def self.to_core_model(document)
      Transform::ToCoreModel.transform(document)
    end

    # Check if this format can transform the given model to CoreModel
    #
    # HTML uses Nokogiri as its model layer. Accepts Nokogiri nodes
    # and CoreModel objects (pass-through).
    #
    # @param model [Object] The model to check
    # @return [Boolean] true if the model is a Nokogiri node or CoreModel
    def self.handles_model?(model)
      model.is_a?(Nokogiri::XML::Node) ||
        model.is_a?(Nokogiri::XML::Document) ||
        model.is_a?(Coradoc::CoreModel::Base)
    end

    def self.to_core(document)
      to_core_model(document)
    end

    # Transform CoreModel to HTML-ready structure
    #
    # @param core_document [Coradoc::CoreModel::Base] CoreModel document
    # @return [Object] HTML-ready structure
    def self.from_core_model(core_document)
      Transform::FromCoreModel.transform(core_document)
    end
  end
end

# Register after all module methods are defined
Coradoc.register_format(:html, Coradoc::Html,
                        aliases: %w[html htm],
                        extensions: %w[.html .htm])
