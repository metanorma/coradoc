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
        HtmlConverter.convert(input, options)
      end

      def self.to_coradoc(input, options = {})
        HtmlConverter.to_coradoc(input, options)
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

      def self.processor_match?(filename)
        %w[.html .htm].any? { |i| filename.downcase.end_with?(i) }
      end

      def self.processor_execute(input, options = {})
        to_coradoc(input, options)
      end

      def self.processor_postprocess(data, options)
        if options[:output_processor] == :adoc
          data.transform_values do |v|
            Input::Html::HtmlConverter.cleanup_result(v, options)
          end
        else
          data
        end
      end

      Coradoc::Input.define(self)
    end
  end

  # Backward compatibility alias
  # Some legacy code references Coradoc::Html::Input instead of Coradoc::Input::Html
  module Html
    Input = Coradoc::Input::Html
  end
end
