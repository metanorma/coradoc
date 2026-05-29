# frozen_string_literal: true

require 'pathname'

module Coradoc
  module Html
    # Configuration for the Liquid template system.
    #
    # Delegates template lookup to TemplateLocator for consistent behavior
    # across global configuration and per-renderer usage.
    #
    # @example Global configuration
    #   Coradoc::Html.configure do |config|
    #     config.template_dirs = ["/path/to/custom/templates"]
    #   end
    class TemplateConfig
      DEFAULT_TEMPLATE_DIR = TemplateLocator::DEFAULT_TEMPLATE_DIR

      attr_accessor :template_dirs

      def initialize(template_dirs: [])
        @template_dirs = Array(template_dirs).map { |dir| Pathname.new(dir) }
      end

      def locator
        @locator ||= TemplateLocator.new(user_dirs: @template_dirs)
      end

      def all_template_dirs
        @template_dirs + [DEFAULT_TEMPLATE_DIR]
      end

      def self.available_templates
        @available_templates ||= begin
          return [] unless DEFAULT_TEMPLATE_DIR.exist?

          DEFAULT_TEMPLATE_DIR
            .glob('*.liquid')
            .map { |f| f.basename('.liquid').to_s.to_sym }
            .sort
        end
      end

      def self.template_path_for(name)
        path = DEFAULT_TEMPLATE_DIR.join("#{name}.liquid")
        path.exist? ? path : nil
      end

      def template_exists?(name)
        locator.exists?(name.to_s)
      end

      def find_template(name)
        locator.find(name.to_s)
      end

      def reset!
        @template_dirs = []
        @locator = nil
      end

      def with_dirs(additional_dirs)
        self.class.new(
          template_dirs: @template_dirs + Array(additional_dirs).map { |d| Pathname.new(d) }
        )
      end
    end

    # Module-level configuration storage
    class << self
      def configuration
        @configuration ||= TemplateConfig.new
      end

      def configure
        yield(configuration) if block_given?
      end

      def reset_configuration!
        @configuration = nil
      end

      def available_templates
        TemplateConfig.available_templates
      end

      def template_path_for(name)
        TemplateConfig.template_path_for(name)
      end
    end
  end
end
