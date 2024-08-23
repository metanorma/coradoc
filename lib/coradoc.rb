# frozen_string_literal: true

require "pathname"

require "parslet"
require "coradoc/version"
require "coradoc/util"
require "coradoc/parser"
require "coradoc/transformer"
require "coradoc/generator"
require "coradoc/converter"
require "coradoc/input"
require "coradoc/output"

module Coradoc
  class Error < StandardError; end

  def self.root
    File.dirname(__dir__)
  end

  def self.root_path
    Pathname.new(Coradoc.root)
  end
end
