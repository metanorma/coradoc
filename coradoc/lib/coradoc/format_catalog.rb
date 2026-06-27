# frozen_string_literal: true

module Coradoc
  # Format registry, detection, and capability introspection. Single
  # source of truth for "what formats exist and what can they do?",
  # extracted from the top-level Coradoc façade. Public API on
  # +Coradoc+ delegates here.
  module FormatCatalog
    class << self
      def registry
        @registry ||= Registry.new
      end

      def register_format(format_name, format_module, **options)
        format_module.extend(FormatModule::Interface) unless format_module.is_a?(FormatModule::Interface)
        registry.register(format_name, format_module, options)
        FormatModule.validate!(format_module, format_name)
      end

      def get_format(format_name)
        registry.get(format_name)
      end

      def registered_formats
        registry.list
      end

      def detect_format(filename)
        ext = File.extname(filename).downcase
        registry.each_key do |name|
          opts = registry.options_for(name)
          return name if opts[:extensions]&.include?(ext)
        end
        nil
      end

      def binary_format?(format)
        opts = registry.options_for(format)
        opts&.fetch(:binary, false) == true
      end

      def normalize_format(name)
        return nil unless name

        key = name.to_s.downcase
        registry.each_key do |fmt_name|
          opts = registry.options_for(fmt_name)
          return fmt_name if opts[:aliases]&.include?(key)
        end
        key.to_sym
      end

      def serialize_format?(format)
        mod = get_format(format)
        return false unless mod

        mod.serialize?
      end

      def parse_format?(format)
        mod = get_format(format)
        return false unless mod

        mod.public_methods.include?(:parse_to_core) || mod.public_methods.include?(:parse)
      end

      def capabilities
        registered_formats.each_with_object({}) do |name, caps|
          caps[name] = {
            parse: parse_format?(name),
            serialize: serialize_format?(name)
          }
        end
      end

      def resolve_output_format(output_file, default: :html)
        return default unless output_file

        detect_format(output_file) || default
      end
    end
  end
end
