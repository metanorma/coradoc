# frozen_string_literal: true

require 'pathname'

module Coradoc
  module Html
    # Configuration for the Liquid template system
    #
    # This class manages template directories and provides utilities
    # for template discovery and customization.
    #
    # @example Global configuration
    #   Coradoc::Html.configure do |config|
    #     config.template_dirs = ["/path/to/custom/templates"]
    #   end
    #
    # @example Per-render configuration
    #   Coradoc::Html.serialize(document, template_dirs: ["/custom/templates"])
    #
    class TemplateConfig
      # Default template directory within the gem
      DEFAULT_TEMPLATE_DIR = Pathname.new(File.join(
                                            File.dirname(__FILE__), 'templates', 'core_model'
                                          )).freeze

      # @return [Array<Pathname>] List of user-provided template directories
      attr_accessor :template_dirs

      # Initialize a new configuration
      #
      # @param template_dirs [Array<String, Pathname>] Custom template directories
      def initialize(template_dirs: [])
        @template_dirs = Array(template_dirs).map { |dir| Pathname.new(dir) }
      end

      # Get all template directories (user + default)
      #
      # @return [Array<Pathname>] All template directories in search order
      def all_template_dirs
        @template_dirs + [DEFAULT_TEMPLATE_DIR]
      end

      # List all available default templates
      #
      # @return [Array<Symbol>] List of template names (without .liquid extension)
      def self.available_templates
        @available_templates ||= begin
          return [] unless DEFAULT_TEMPLATE_DIR.exist?

          DEFAULT_TEMPLATE_DIR
            .glob('*.liquid')
            .map { |f| f.basename('.liquid').to_s.to_sym }
            .sort
        end
      end

      # Get the path to a specific default template
      #
      # @param name [Symbol, String] Template name (e.g., :bibliography)
      # @return [Pathname, nil] Path to the template file, or nil if not found
      def self.template_path_for(name)
        path = DEFAULT_TEMPLATE_DIR.join("#{name}.liquid")
        path.exist? ? path : nil
      end

      # Check if a template exists
      #
      # @param name [Symbol, String] Template name
      # @return [Boolean] True if template exists in any directory
      def template_exists?(name)
        all_template_dirs.any? do |dir|
          dir.join("#{name}.liquid").exist?
        end
      end

      # Find a template by name
      #
      # @param name [Symbol, String] Template name
      # @return [Pathname, nil] Path to the first matching template
      def find_template(name)
        all_template_dirs.each do |dir|
          path = dir.join("#{name}.liquid")
          return path if path.exist?
        end
        nil
      end

      # Reset configuration to defaults
      #
      # @return [void]
      def reset!
        @template_dirs = []
      end

      # Create a copy of this configuration with additional directories
      #
      # @param additional_dirs [Array<String, Pathname>] Extra directories
      # @return [TemplateConfig] New configuration with merged directories
      def with_dirs(additional_dirs)
        self.class.new(
          template_dirs: @template_dirs + Array(additional_dirs).map { |d| Pathname.new(d) }
        )
      end
    end

    # Module-level configuration storage
    class << self
      # Get the global configuration
      #
      # @return [TemplateConfig] The global configuration
      def configuration
        @configuration ||= TemplateConfig.new
      end

      # Configure the template system
      #
      # @yield [TemplateConfig] Yields the configuration object
      # @return [void]
      #
      # @example
      #   Coradoc::Html.configure do |config|
      #     config.template_dirs = ["/path/to/templates"]
      #   end
      def configure
        yield(configuration) if block_given?
      end

      # Reset configuration to defaults
      #
      # @return [void]
      def reset_configuration!
        @configuration = nil
      end

      # List all available default templates
      #
      # @return [Array<Symbol>] List of template names
      def available_templates
        TemplateConfig.available_templates
      end

      # Get the path to a default template
      #
      # @param name [Symbol, String] Template name
      # @return [Pathname, nil] Path to template or nil
      def template_path_for(name)
        TemplateConfig.template_path_for(name)
      end
    end
  end
end
