# frozen_string_literal: true

require 'digest'
require 'nokogiri'
require 'coradoc/input'

module Coradoc
  module Input
    module Html
      # Autoload all components
      autoload :Errors, 'coradoc/html/input/errors'
      autoload :Cleaner, 'coradoc/html/input/cleaner'
      autoload :Config, 'coradoc/html/input/config'
      autoload :Plugin, 'coradoc/html/input/plugin'
      autoload :Postprocessor, 'coradoc/html/input/postprocessor'
      autoload :Converters, 'coradoc/html/input/converters'
      autoload :HtmlConverter, 'coradoc/html/input/html_converter'

      def self.convert(input, options = {})
        HtmlConverter.to_core_model(input, options)
      end

      def self.to_coradoc(input, options = {})
        HtmlConverter.to_core_model(input, options)
      end

      def self.config
        @config ||= Config.new
        yield @config if block_given?
        @config
      end

      def self.cleaner
        @cleaner ||= Cleaner.new
      end

      def self.processor_id
        :html
      end

      extend Coradoc::Html::FormatDetection

      def self.processor_match?(filename)
        html_extension?(filename)
      end

      def self.processor_execute(input, options = {})
        to_coradoc(input, options)
      end

      def self.processor_postprocess(data, options)
        if options[:output_processor] == :adoc
          data.transform_values { |v| clean_output(v, options) }
        else
          data
        end
      end

      def self.clean_output(result, options = {})
        config.with(options) do
          plugin_instances = HtmlConverter.prepare_plugin_instances(options)

          result = HtmlConverter.track_time('Cleaning up the result') do
            cleaner.tidy(result)
          end

          plugin_instances.each do |plugin|
            plugin.output_string = result
            HtmlConverter.track_time("Postprocessing output string with #{plugin.name} plugin") do
              plugin.postprocess_output_string
            end
            result = plugin.output_string
          end

          result
        end
      end

      Coradoc::Input.define(self)
    end
  end

  module Html
    Input = Coradoc::Input::Html
  end
end
