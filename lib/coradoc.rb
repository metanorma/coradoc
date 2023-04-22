# frozen_string_literal: true

require "asciidoctor"
require "coradoc/version"
require "coradoc/document/base"
require "coradoc/parser"
require "coradoc/transformer"

module Coradoc
  class Error < StandardError; end

  def self.root
    File.dirname(__dir__)
  end

  def self.root_path
    Pathname.new(Coradoc.root)
  end
end
