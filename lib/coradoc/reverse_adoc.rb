# frozen_string_literal: true

require "digest"
require "nokogiri"
require_relative "../coradoc"
require_relative "reverse_adoc/errors"
require_relative "reverse_adoc/cleaner"
require_relative "reverse_adoc/config"
require_relative "reverse_adoc/converters"
require_relative "reverse_adoc/converters/base"
require_relative "reverse_adoc/html_converter"

module Coradoc::ReverseAdoc
  def self.convert(input, options = {})
    Coradoc::ReverseAdoc::HtmlConverter.convert(input, options)
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
