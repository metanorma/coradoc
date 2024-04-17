# frozen_string_literal: true

require "pathname"

require "parslet"
require "coradoc/version"

require "coradoc/parser"
require "coradoc/transformer"
require "coradoc/generator"

module Coradoc
  class Error < StandardError; end

  def self.root
    File.dirname(__dir__)
  end

  def self.root_path
    Pathname.new(Coradoc.root)
  end
end
