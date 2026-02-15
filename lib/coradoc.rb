# frozen_string_literal: true

require "pathname"

require "parslet"
require_relative "coradoc/logger"
require_relative "coradoc/version"
require_relative "coradoc/util"
require_relative "coradoc/parser"
require_relative "coradoc/transformer"
require_relative "coradoc/generator"
require_relative "coradoc/converter"
require_relative "coradoc/input"
require_relative "coradoc/output"

module Coradoc
  class Error < StandardError; end

  def self.root
    File.dirname(__dir__)
  end

  def self.root_path
    Pathname.new(Coradoc.root)
  end
end
