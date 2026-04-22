# frozen_string_literal: true

module Coradoc
  module Html
    module Theme
      # Theme registry for managing and retrieving theme renderers
      #
      # The registry maintains a collection of available themes and provides
      # methods for registration, lookup, and validation.
      #
      # @example Registering a custom theme
      #   class MyCustomTheme < Coradoc::Html::Theme::Base
      #     def render
      #       "<h1>Custom HTML</h1>"
      #     end
      #   end
      #
      #   Coradoc::Html::Theme::Registry.register(:my_custom, MyCustomTheme)
      #
      # @example Using a theme
      #   renderer = Coradoc::Html::Theme::Registry.find(:my_custom)
      #   renderer.new(document, options).render
      class Registry
        class << self
          # Registered themes mapping
          #
          # @return [Hash] Theme name to renderer class mapping
          def themes
            @themes ||= {}
          end

          # Register a theme renderer
          #
          # @param name [Symbol] Theme name (e.g., :classic, :modern)
          # @param renderer_class [Class] Theme renderer class
          # @raise [ArgumentError] if renderer_class is not a Theme::Base subclass
          #
          # @example Register a theme
          #   Registry.register(:my_theme, MyThemeRenderer)
          def register(name, renderer_class)
            unless renderer_class.is_a?(Class) &&
                   renderer_class <= Coradoc::Html::Theme::Base
              raise ArgumentError,
                    'Theme renderer must be a subclass of Coradoc::Html::Theme::Base, ' \
                    "got: #{renderer_class}"
            end

            themes[name] = renderer_class
          end

          # Find a theme renderer by name
          #
          # @param name [Symbol] Theme name
          # @return [Class, nil] Theme renderer class or nil if not found
          #
          # @example Find a theme
          #   renderer = Registry.find(:modern)
          def find(name)
            themes[name]
          end

          # Check if a theme is registered
          #
          # @param name [Symbol] Theme name
          # @return [Boolean] true if theme is registered
          #
          # @example Check theme existence
          #   Registry.registered?(:modern) # => true
          def registered?(name)
            themes.key?(name)
          end

          # Get all registered theme names
          #
          # @return [Array<Symbol>] List of registered theme names
          #
          # @example List all themes
          #   Registry.all_theme_names # => [:classic, :modern]
          def all_theme_names
            themes.keys.sort
          end

          # Get default theme name
          #
          # @return [Symbol] Default theme name
          def default_theme
            :classic
          end

          # Resolve theme from options
          #
          # Returns the theme renderer class based on the provided options.
          # Falls back to default theme if not specified or if theme not found.
          #
          # @param options [Hash] Rendering options
          # @return [Class] Theme renderer class
          #
          # @example Resolve theme from options
          #   renderer = Registry.resolve_from_options(theme: :modern)
          def resolve_from_options(options = {})
            theme_name = options.fetch(:theme, default_theme)

            renderer_class = find(theme_name)
            return renderer_class if renderer_class

            # Theme not found, fall back to default
            Coradoc::Logger.warn(
              "Theme '#{theme_name}' not found, falling back to '#{default_theme}'"
            )

            find(default_theme) || raise("Default theme '#{default_theme}' not registered")
          end

          # Auto-register a theme class
          #
          # This method is called by theme classes when they are loaded.
          # It extracts the theme name from the class name and registers it.
          #
          # @param renderer_class [Class] Theme renderer class
          #
          # @example Auto-register from within a theme class
          #   class ModernTheme < Coradoc::Output::Html::Theme::Base
          #     Coradoc::Output::Html::Theme::Registry.auto_register(self)
          #   end
          def auto_register(renderer_class)
            # Extract theme name from class name
            # e.g., ModernRenderer -> :modern, ClassicRenderer -> :classic
            class_name = renderer_class.name.split('::').last

            # Remove "Renderer" suffix if present
            theme_name = class_name.sub(/Renderer$/, '')
                                   .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                                   .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                                   .downcase
                                   .to_sym

            register(theme_name, renderer_class)
          end

          # Clear all registered themes (mainly for testing)
          #
          # @return [void]
          #
          # @example Clear registry
          #   Registry.clear
          def clear
            @themes = {}
          end
        end
      end
    end
  end
end
