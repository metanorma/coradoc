# frozen_string_literal: true

require "digest"
require "nokogiri"
require "coradoc/input"
require_relative "html/errors"
require_relative "html/cleaner"
require_relative "html/config"
require_relative "html/converters"
require_relative "html/converters/base"
require_relative "html/html_converter"
require_relative "html/plugin"
require_relative "html/postprocessor"

module Coradoc
  module Input::Html
    def self.convert(input, options = {})
      Coradoc::Input::Html::HtmlConverter.convert(input, options)
    end

    def self.to_coradoc(input, options = {})
      Input::Html::HtmlConverter.to_coradoc(input, options)
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
