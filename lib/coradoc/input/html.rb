# frozen_string_literal: true

require "digest"
require "nokogiri"
require_relative "../input"
require_relative "html/errors"
require_relative "html/cleaner"
require_relative "html/config"
require_relative "html/converters"
require_relative "html/converters/base"
require_relative "html/html_converter"
require_relative "html/plugin"
require_relative "html/postprocessor"

module Coradoc
  module Input::HTML
    def self.convert(input, options = {})
      Coradoc::Input::HTML::HtmlConverter.convert(input, options)
    end

    def self.config
      @config ||= Config.new
      yield @config if block_given?
      @config
    end

    def self.cleaner
      @cleaner ||= Cleaner.new
    end
  end
end
