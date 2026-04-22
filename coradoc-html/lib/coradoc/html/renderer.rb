# frozen_string_literal: true

require 'liquid'
require_relative 'template_locator'
require_relative 'template_helpers'

module Coradoc
  module Html
    # Unified template renderer using Liquid templates for CoreModel types
    #
    # This class provides a template-based rendering system where:
    # - Users provide template directories (checked in order, first wins)
    # - System falls back to default templates if enabled
    # - CoreModel objects are automatically converted to Liquid drops via to_liquid
    #
    # @example Basic usage with default templates only
    #   renderer = Coradoc::Html::Renderer.new
    #   html = renderer.render(bibliography_element)
    #
    # @example With custom template directory (falls back to defaults)
    #   renderer = Coradoc::Html::Renderer.new(
    #     template_dirs: ["./my_templates"]
    #   )
    #   html = renderer.render(bibliography_element)
    #
    # @example Multiple template dirs with priority (first wins)
    #   renderer = Coradoc::Html::Renderer.new(
    #     template_dirs: ["./project_templates", "./shared_templates"],
    #     include_default_templates: true
    #   )
    #
    # @example Custom templates only, no defaults
    #   renderer = Coradoc::Html::Renderer.new(
    #     template_dirs: ["./my_templates"],
    #     include_default_templates: false
    #   )
    #
    class Renderer
      # Mapping of CoreModel class names to template type names
      TEMPLATE_TYPE_MAP = {
        'Coradoc::CoreModel::Bibliography' => 'bibliography',
        'Coradoc::CoreModel::BibliographyEntry' => 'bibliography_entry',
        'Coradoc::CoreModel::StructuralElement' => 'structural_element',
        'Coradoc::CoreModel::Block' => 'block',
        'Coradoc::CoreModel::ListBlock' => 'list_block',
        'Coradoc::CoreModel::ListItem' => 'list_item',
        'Coradoc::CoreModel::Table' => 'table',
        'Coradoc::CoreModel::TableRow' => 'table_row',
        'Coradoc::CoreModel::TableCell' => 'table_cell',
        'Coradoc::CoreModel::Image' => 'image',
        'Coradoc::CoreModel::AnnotationBlock' => 'annotation_block',
        'Coradoc::CoreModel::InlineElement' => 'inline_element',
        'Coradoc::CoreModel::Paragraph' => 'paragraph',
        'Coradoc::CoreModel::Term' => 'term',
        'Coradoc::CoreModel::Footnote' => 'footnote',
        'Coradoc::CoreModel::FootnoteReference' => 'footnote_reference',
        'Coradoc::CoreModel::Toc' => 'toc',
        'Coradoc::CoreModel::TocEntry' => 'toc_entry',
        'Coradoc::CoreModel::DefinitionList' => 'definition_list',
        'Coradoc::CoreModel::DefinitionItem' => 'definition_item',
        'Coradoc::CoreModel::Abbreviation' => 'abbreviation'
      }.freeze

      # Default template directory (built-in templates)
      DEFAULT_TEMPLATE_DIR = Pathname.new(File.join(File.dirname(__FILE__), 'templates', 'core_model'))

      attr_reader :template_dirs, :include_default_templates, :options

      # Initialize the renderer
      #
      # @param template_dirs [Array<String>, String, nil] Custom template directories
      #   Searched in order (first match wins). Can be a single path or array.
      # @param include_default_templates [Boolean] Whether to fall back to built-in
      #   templates when not found in template_dirs. Default: true
      # @param options [Hash] Additional options
      # @option options [Boolean] :strict Raise error if template not found (default: false)
      # @option options [Boolean] :cache_templates Cache parsed templates (default: true)
      #
      def initialize(template_dirs: nil, include_default_templates: true, options: {})
        @template_dirs = normalize_template_dirs(template_dirs)
        @include_default_templates = include_default_templates
        @options = { cache_templates: true, strict: false }.merge(options)
        @template_cache = {}
        ensure_core_model_drops
      end

      # Render a CoreModel element to HTML
      #
      # @param element [Coradoc::CoreModel::Base] The element to render
      # @param context [Hash] Additional context for the template
      # @return [String] Rendered HTML
      def render(element, context = {})
        return '' if element.nil?

        # Ensure liquid drop class exists for lutaml-model elements
        ensure_drop_class(element)

        # Handle arrays
        return element.map { |e| render(e, context) }.join("\n") if element.is_a?(Array)

        # Handle primitives
        case element
        when String
          return escape_html(element)
        when Numeric, TrueClass, FalseClass
          return element.to_s
        when NilClass
          return ''
        end

        # Get template type name for this element
        type_name = template_type_for(element)
        return render_fallback(element, context) unless type_name

        # Find the template file
        template_path = find_template(type_name)
        return render_fallback(element, context) if template_path.nil?

        # Load and render the template
        template = load_template(template_path)
        if template
          render_with_template(template, element, context)
        else
          render_fallback(element, context)
        end
      end

      # Get list of all available template names
      #
      # @return [Array<String>] List of template names (without .liquid extension)
      def available_templates
        templates = Set.new

        # Scan user template directories
        @template_dirs.each do |dir|
          core_model_dir = File.join(dir, 'core_model')
          next unless File.directory?(core_model_dir)

          Dir.glob(File.join(core_model_dir, '*.liquid')).each do |file|
            templates << File.basename(file, '.liquid')
          end
        end

        # Scan default templates if included
        if @include_default_templates && File.directory?(DEFAULT_TEMPLATE_DIR)
          Dir.glob(File.join(DEFAULT_TEMPLATE_DIR, '*.liquid')).each do |file|
            templates << File.basename(file, '.liquid')
          end
        end

        templates.to_a.sort
      end

      # Check if a template exists for a given type
      #
      # @param type_name [String] Template type name (e.g., "bibliography")
      # @return [Boolean] True if template exists
      def template_exists?(type_name)
        !find_template(type_name).nil?
      end

      # Register a custom template type mapping
      #
      # @param class_name [String] Full class name (e.g., "Coradoc::CoreModel::Bibliography")
      # @param type_name [String] Template type name (e.g., "bibliography")
      def self.register_type(class_name, type_name)
        @custom_type_map ||= {}
        @custom_type_map[class_name] = type_name
      end

      # Get custom type mappings
      def self.custom_type_map
        @custom_type_map ||= {}
      end

      private

      # Ensure liquid drop class exists for lutaml-model elements
      # (lutaml-model may not create drops if Liquid was loaded after the model class)
      def ensure_drop_class(element)
        klass = element.class
        if klass.respond_to?(:register_class_if_liquid_defined) &&
           klass.respond_to?(:base_drop_class) && !klass.base_drop_class
          klass.register_class_if_liquid_defined
        end
      end

      # Ensure all CoreModel drop classes are registered
      # (lutaml-model only creates drops when Liquid is already loaded at class definition time)
      def ensure_core_model_drops
        return unless defined?(Coradoc::CoreModel)

        CoreModel.constants(false).each do |const_name|
          klass = CoreModel.const_get(const_name)
          next unless klass.is_a?(Class)
          next unless klass.respond_to?(:register_class_if_liquid_defined)
          next if klass.respond_to?(:base_drop_class) && klass.base_drop_class

          klass.register_class_if_liquid_defined
        rescue StandardError
          nil
        end
      end

      # Normalize template_dirs to an array of absolute paths
      def normalize_template_dirs(dirs)
        return [] if dirs.nil?

        Array(dirs).map do |dir|
          path = Pathname.new(dir)
          path.absolute? ? path.to_s : File.expand_path(dir)
        end
      end

      # Find template file for a type name
      # Searches template_dirs in order, then defaults if enabled
      #
      # @param type_name [String] Template type name
      # @return [String, nil] Path to template file or nil
      def find_template(type_name)
        template_file = "#{type_name}.liquid"

        # Search user template directories in order
        @template_dirs.each do |dir|
          # Check core_model subdirectory first
          core_model_dir = File.join(dir, 'core_model')
          path = File.join(core_model_dir, template_file)
          return path if File.file?(path)

          # Also check the directory itself
          path = File.join(dir, template_file)
          return path if File.file?(path)
        end

        # Fall back to default templates if enabled
        if @include_default_templates
          path = File.join(DEFAULT_TEMPLATE_DIR, template_file)
          return path if File.file?(path)
        end

        nil
      end

      # Get template type name for an element
      #
      # @param element [Object] The element
      # @return [String, nil] Template type name or nil
      def template_type_for(element)
        class_name = element.class.name

        # Check custom registrations first
        self.class.custom_type_map[class_name] ||
          TEMPLATE_TYPE_MAP[class_name] ||
          derive_type_name(class_name)
      end

      # Derive template type name from class name
      #
      # @param class_name [String] Full class name
      # @return [String] Derived type name
      def derive_type_name(class_name)
        parts = class_name.split('::')
        return nil unless parts.length >= 2

        # Just use the class name, underscored
        parts.last
             .gsub(/([A-Z])/, '_\1')
             .downcase
             .sub(/^_/, '')
      end

      # Load a template from file
      #
      # @param path [String] Path to template file
      # @return [Liquid::Template, nil] Parsed template or nil
      def load_template(path)
        cache_key = path.to_s
        return @template_cache[cache_key] if @template_cache.key?(cache_key)

        template_content = File.read(path)
        template = Liquid::Template.parse(template_content)
        @template_cache[cache_key] = template if @options[:cache_templates]
        template
      rescue Liquid::SyntaxError => e
        warn "Template syntax error in #{path}: #{e.message}"
        nil
      end

      # Render element with template
      #
      # @param template [Liquid::Template] The template
      # @param element [Object] The element to render
      # @param context [Hash] Additional context
      # @return [String] Rendered HTML
      def render_with_template(template, element, context)
        # Convert element to Liquid Drop
        liquid_drop = element.to_liquid

        # If no extra context, render with drop directly
        if context.empty?
          return template.render(liquid_drop, {
                                   registers: { renderer: self }
                                 }).strip
        end

        # Build hash from drop's known attributes
        # The Drop exposes attributes via method calls
        assigns = build_assigns_from_drop(liquid_drop).merge(context)

        # Render with registers containing renderer for recursive calls
        template.render(assigns, {
                          registers: { renderer: self }
                        }).strip
      end

      # Build a hash from a Liquid Drop's accessible attributes
      def build_assigns_from_drop(drop)
        # Get all attribute names from the drop's class
        # These are defined by the Lutaml::Model attributes
        assigns = {}

        # Common attributes that most CoreModel types have
        %w[id title content children element_type language lines
           delimiter_type delimiter_length metadata_entries element_attributes
           text href alt src level entries items rows cells
           anchor term definition abbreviations].each do |key|
          assigns[key] = drop[key] if drop.key?(key)
        end

        assigns
      end

      # Fallback rendering when no template found
      #
      # @param element [Object] The element
      # @param context [Hash] Context
      # @return [String] Rendered HTML
      def render_fallback(element, _context)
        raise "No template found for #{element.class.name}" if @options[:strict]

        # Simple fallback - convert to string
        class_name = element.class.name
        simple_name = class_name.split('::').last
        underscored = simple_name&.gsub(/([A-Z])/, '_\1')&.downcase&.sub(/^_/, '') || 'unknown'

        "<div class=\"element element-#{underscored}\">#{escape_html(element.to_s)}</div>"
      end

      # Escape HTML entities
      def escape_html(text)
        text.to_s
            .gsub(/&/, '&amp;')
            .gsub(/</, '&lt;')
            .gsub(/>/, '&gt;')
            .gsub(/"/, '&quot;')
            .gsub(/'/, '&#39;')
      end
    end

    # Backwards compatibility alias
    TemplateRenderer = Renderer
  end
end
