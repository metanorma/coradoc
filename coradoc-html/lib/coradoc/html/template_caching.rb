# frozen_string_literal: true

require 'liquid'

module Coradoc
  module Html
    # Shared template caching logic for Renderer and LayoutRenderer.
    #
    # Both Renderer#find_and_load_template and LayoutRenderer#load_layout
    # implement identical caching patterns (check cache, read file, parse
    # Liquid, store in cache, rescue syntax errors). This module provides
    # a single implementation.
    module TemplateCaching
      private

      def load_template(cache:, cache_key:, path:)
        return cache[cache_key] if cache.key?(cache_key)

        return nil unless path && File.exist?(path)

        template_content = File.read(path)
        template = Liquid::Template.parse(template_content)
        cache[cache_key] = template
        template
      rescue Liquid::SyntaxError => e
        warn "Template syntax error in #{path}: #{e.message}"
        nil
      end
    end
  end
end
