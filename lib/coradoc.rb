# frozen_string_literal: true

require "coradoc/oscal"
require "coradoc/version"
require "coradoc/document/base"
require "coradoc/parser"
require "coradoc/transformer"

# Module
require "coradoc/asciidoc/bibdata"
require "coradoc/asciidoc/section"

module Coradoc
  class Error < StandardError; end

  def self.root
    File.dirname(__dir__)
  end

  def self.root_path
    Pathname.new(Coradoc.root)
  end
end
