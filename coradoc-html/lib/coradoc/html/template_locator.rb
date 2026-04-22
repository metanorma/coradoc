# frozen_string_literal: true

require 'liquid'
require 'pathname'

module Coradoc
  module Html
    # Locates Liquid templates from filesystem with fallback support
    #
    # This class implements a template lookup algorithm:
    # 1. Check user's template directories in order (first match wins)
    # 2. Fall back to default templates if not found
    # 3. Return nil if no template found (caller decides fallback)
    #
    # @example Basic usage
    #   locator = TemplateLocator.new(
    #     user_dirs: ["/path/to/templates"],
    #     default_dir: "/default/templates"
    #   )
    #   locator.find("bibliography") # => "/path/to/templates/bibliography.liquid"
    #
    class TemplateLocator
      # Default template subdirectory within each template root
      CORE_MODEL_DIR = 'core_model'

      attr_reader :user_dirs, :default_dir

      # Initialize the locator
      #
      # @param user_dirs [Array<String>] User template directories (checked first)
      # @param default_dir [String] Default templates directory (fallback)
      def initialize(user_dirs: [], default_dir: nil)
        @user_dirs = Array(user_dirs).map { |d| Pathname.new(d) }
        @default_dir = default_dir ? Pathname.new(default_dir) : default_template_dir
        @cache = {}
      end

      # Find a template by type name
      #
      # @param type_name [String] The template type (e.g., "bibliography", "section")
      # @return [Pathname, nil] Path to template file or nil if not found
      def find(type_name)
        return @cache[type_name] if @cache.key?(type_name)

        # First check user directories
        @user_dirs.each do |dir|
          template_path = dir / CORE_MODEL_DIR / "#{type_name}.liquid"
          if template_path.exist?
            @cache[type_name] = template_path
            return template_path
          end
        end

        # Then check default directory
        if @default_dir
          template_path = @default_dir / "#{type_name}.liquid"
          if template_path.exist?
            @cache[type_name] = template_path
            return template_path
          end
        end

        @cache[type_name] = nil
        nil
      end

      # Check if a template exists (without loading it)
      #
      # @param type_name [String] The template type
      # @return [Boolean] True if template exists
      def exists?(type_name)
        !find(type_name).nil?
      end

      # Get all available template types
      #
      # @return [Array<String>] List of available template names
      def available_templates
        types = Set.new

        # Collect from user directories
        @user_dirs.each do |dir|
          core_model_path = dir / CORE_MODEL_DIR
          next unless core_model_path.exist? && core_model_path.directory?

          core_model_path.glob('*.liquid') do |f|
            types.add(f.basename('.liquid').to_s)
          end
        end

        # Collect from default directory
        if @default_dir&.exist? && @default_dir.directory?
          @default_dir.glob('*.liquid') do |f|
            types.add(f.basename('.liquid').to_s)
          end
        end

        types.to_a.sort
      end

      # Get the default template directory path
      #
      # @return [Pathname] Path to default templates
      def default_template_dir
        Pathname.new(File.join(File.dirname(__FILE__), 'templates', CORE_MODEL_DIR))
      end

      # Clear the template cache (useful when template directories change)
      def clear_cache
        @cache.clear
      end
    end
  end
end
