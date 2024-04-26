# frozen_string_literal: true

require "pathname"

require "parslet"
require_relative "coradoc/version"
require_relative "coradoc/parser"
require_relative "coradoc/transformer"
require_relative "coradoc/generator"

module Coradoc
  class Error < StandardError; end

  def self.root
    File.dirname(__dir__)
  end

  def self.root_path
    Pathname.new(Coradoc.root)
  end
end
