# frozen_string_literal: true

# Coradoc - Canonical Document Model and Transformation Hub
#
# Coradoc provides a hub-and-spoke architecture for document transformations.
# The CoreModel serves as the canonical, format-agnostic representation,
# enabling transformations between AsciiDoc, HTML, Markdown, DOCX, and more.
#
# @example Converting between formats
#   require 'coradoc'
#   html = Coradoc.convert("# Hello", from: :markdown, to: :html)
#
# @example Parsing and serializing
#   doc = Coradoc.parse("# Title\n\nContent", format: :markdown)
#   html = Coradoc.serialize(doc, to: :html)
#
# @example File-based conversion
#   doc = Coradoc.parse_file("input.md")
#   html = Coradoc.convert_file("input.md", to: :html)
#
# @example Manipulating documents
#   doc = Coradoc.parse(text, format: :asciidoc)
#   html = Coradoc.serialize(doc, to: :html)
#
# @example Building documents programmatically
#   doc = Coradoc.build do |d|
#     d.title = "My Document"
#     d.children << Coradoc::CoreModel::ParagraphBlock.new(content: "Hello")
#   end
#   Coradoc.serialize(doc, to: :html)

require_relative 'coradoc/coradoc'
require_relative 'coradoc/version'

module Coradoc
  autoload :CLI, 'coradoc/cli'
  autoload :Visitor, 'coradoc/visitor'
  autoload :LinkRewriter, 'coradoc/link_rewriter'
  autoload :RelativePath, 'coradoc/relative_path'
end
