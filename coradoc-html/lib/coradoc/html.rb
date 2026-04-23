# frozen_string_literal: true

# Load HTML input module to register with Coradoc::Input
require 'coradoc/html/input'
# Load HTML output module to register with Coradoc::Output
require 'coradoc/html/output'

module Coradoc
  module Html
    # Register HTML format with coradoc when loaded
    def self.register_with_coradoc
      return if @registered

      # Register with the main coradoc registry
      Coradoc.register_format(:html, self) if Coradoc.respond_to?(:register_format)

      @registered = true
    end

    # Call registration when this module is included/required
    register_with_coradoc

    module Converters
      # Autoload HTML converters - they will be loaded when accessed
      autoload :Base, 'coradoc/html/converters/base'
      autoload :Admonition, 'coradoc/html/converters/admonition'
      autoload :AttributeReference, 'coradoc/html/converters/attribute_reference'
      autoload :Attribute, 'coradoc/html/converters/attribute'
      autoload :Audio, 'coradoc/html/converters/audio'
      autoload :BibliographyEntry, 'coradoc/html/converters/bibliography_entry'
      autoload :Bibliography, 'coradoc/html/converters/bibliography'
      autoload :BlockImage, 'coradoc/html/converters/block_image'
      autoload :Bold, 'coradoc/html/converters/bold'
      autoload :Break, 'coradoc/html/converters/break'
      autoload :CommentBlock, 'coradoc/html/converters/comment_block'
      autoload :CommentLine, 'coradoc/html/converters/comment_line'
      autoload :CrossReference, 'coradoc/html/converters/cross_reference'
      autoload :Document, 'coradoc/html/converters/document'
      autoload :Example, 'coradoc/html/converters/example'
      autoload :Highlight, 'coradoc/html/converters/highlight'
      autoload :Include, 'coradoc/html/converters/include'
      autoload :InlineImage, 'coradoc/html/converters/inline_image'
      autoload :Italic, 'coradoc/html/converters/italic'
      autoload :LineBreak, 'coradoc/html/converters/line_break'
      autoload :Link, 'coradoc/html/converters/link'
      autoload :ListItem, 'coradoc/html/converters/list_item'
      autoload :Listing, 'coradoc/html/converters/listing'
      autoload :Literal, 'coradoc/html/converters/literal'
      autoload :Monospace, 'coradoc/html/converters/monospace'
      autoload :Ordered, 'coradoc/html/converters/ordered'
      autoload :Open, 'coradoc/html/converters/open'
      autoload :Paragraph, 'coradoc/html/converters/paragraph'
      autoload :Quote, 'coradoc/html/converters/quote'
      autoload :ReviewerComment, 'coradoc/html/converters/reviewer_comment'
      autoload :ReviewerNote, 'coradoc/html/converters/reviewer_note'
      autoload :Section, 'coradoc/html/converters/section'
      autoload :Sidebar, 'coradoc/html/converters/sidebar'
      autoload :Source, 'coradoc/html/converters/source'
      autoload :SourceCode, 'coradoc/html/converters/source_code'
      autoload :Span, 'coradoc/html/converters/span'
      autoload :Strikethrough, 'coradoc/html/converters/strikethrough'
      autoload :Subscript, 'coradoc/html/converters/subscript'
      autoload :Superscript, 'coradoc/html/converters/superscript'
      autoload :TableCell, 'coradoc/html/converters/table_cell'
      autoload :TableRow, 'coradoc/html/converters/table_row'
      autoload :Table, 'coradoc/html/converters/table'
      autoload :Term, 'coradoc/html/converters/term'
      autoload :TextElement, 'coradoc/html/converters/text_element'
      autoload :Underline, 'coradoc/html/converters/underline'
      autoload :Unordered, 'coradoc/html/converters/unordered'
      autoload :Verse, 'coradoc/html/converters/verse'
      autoload :Video, 'coradoc/html/converters/video'
    end

    # Autoload HTML components
    autoload :Config, 'coradoc/html/config'
    autoload :Base, 'coradoc/html/base'
    autoload :Entity, 'coradoc/html/entity'
    autoload :ElementMapping, 'coradoc/html/element_mapping'

    # Autoload HTML output converters
    autoload :ConverterBase, 'coradoc/html/converter_base'
    autoload :Static, 'coradoc/html/static'
    autoload :Spa, 'coradoc/html/spa'

    # Theme system
    autoload :Theme, 'coradoc/html/theme'
    autoload :TemplateLocator, 'coradoc/html/template_locator'
    autoload :TemplateConfig, 'coradoc/html/template_config'
    autoload :TemplateHelpers, 'coradoc/html/template_helpers'
    autoload :Renderer, 'coradoc/html/renderer'

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

      unless defined?(Coradoc::CoreModel::Base) &&
             document.is_a?(Coradoc::CoreModel::Base)
        raise ArgumentError,
              'coradoc-html only accepts CoreModel types. ' \
              "Got: #{document.class}. " \
              'Transform your document to CoreModel before passing to HTML conversion.'
      end

      document
    end

    # Parse HTML content and return CoreModel elements (may be an Array)
    def self.parse(html, options = {})
      # Input::Html is autoloaded via Coradoc::Input
      ::Coradoc::Html::Input.to_coradoc(html, options)
    end

    # Parse HTML content directly into a CoreModel document
    #
    # Unlike #parse which returns an Array of CoreModel elements,
    # this wraps the result into a top-level StructuralElement document
    # suitable for use with Coradoc.serialize and other CoreModel pipelines.
    #
    # @param html [String] HTML content
    # @param options [Hash] Parse options
    # @return [Coradoc::CoreModel::StructuralElement] CoreModel document
    def self.parse_to_core(html, options = {})
      elements = parse(html, options)

      return elements if elements.is_a?(Coradoc::CoreModel::Base)

      # Extract document title from the first heading element
      title = nil
      children = elements
      if elements.is_a?(Array) && !elements.empty?
        first = elements.first
        if first.is_a?(Coradoc::CoreModel::StructuralElement) &&
           first.element_type == 'section' && first.level == 1
          title = first.title
          children = first.children + elements[1..]
        end
      end

      Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: title,
        children: Array(children)
      )
    end

    # Parse HTML file
    def self.from_file(filename, **options)
      content = File.read(filename)
      parse(content, **options)
    end

    # Serialize CoreModel document to HTML
    #
    # Uses the theme system to render HTML. Default theme is :classic.
    #
    # @param document [Coradoc::CoreModel::Base] CoreModel document to serialize
    # @param options [Hash] Output options
    # @return [String] HTML output
    def self.serialize(document, options = {})
      # Validate input is CoreModel
      validate_core_model!(document)

      # Trigger theme autoloads to ensure renderers are registered
      Theme::ClassicRenderer if options[:theme].nil? || options[:theme] == :classic
      Theme::ModernRenderer if options[:theme] == :modern

      # Use theme registry to find and use the appropriate renderer
      theme = options[:theme] || :classic
      renderer_class = Theme::Registry.find(theme)
      renderer = renderer_class.new(document, options)
      renderer.render_html5
    end

    # Serialize CoreModel document to static HTML
    #
    # Uses the classic theme renderer for traditional HTML output.
    #
    # @param document [Coradoc::CoreModel::Base] CoreModel document to serialize
    # @param config [Hash, Static::Configuration] Static converter configuration
    # @return [String] HTML output
    def self.serialize_static(document, config = {})
      # Validate input is CoreModel
      validate_core_model!(document)

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
      # Validate input is CoreModel
      validate_core_model!(document)

      Spa.convert(document, config)
    end

    # Serialize CoreModel document to HTML with specified format
    #
    # @param document [Coradoc::CoreModel::Base] CoreModel document to serialize
    # @param format [Symbol] Output format (:static, :spa, :classic)
    # @param options [Hash] Converter options
    # @return [String] HTML output
    def self.serialize_as(document, format, options = {})
      # Validate input is CoreModel
      validate_core_model!(document)

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

    # Transform CoreModel to HTML-ready structure
    #
    # @param core_document [Coradoc::CoreModel::Base] CoreModel document
    # @return [Object] HTML-ready structure
    def self.from_core_model(core_document)
      Transform::FromCoreModel.transform(core_document)
    end
  end
end
