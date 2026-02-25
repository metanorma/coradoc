# frozen_string_literal: true

# Coradoc - Canonical Document Model and Transformation Hub
#
# Coradoc provides a hub-and-spoke architecture for document transformations.
# The CoreModel serves as the canonical, format-agnostic representation,
# enabling transformations between AsciiDoc, HTML, Markdown, and more.
#
# @example Basic usage with AsciiDoc
#   require 'coradoc'
#   require 'coradoc/asciidoc'
#
#   doc = Coradoc::AsciiDoc.parse_file('document.adoc')
#   core = Coradoc::AsciiDoc::Transform::ToCoreModel.transform(doc)
#
# @example Output to HTML
#   require 'coradoc/html'
#
#   html = Coradoc::Html::Transform::FromCoreModel.transform(core)
#   puts html.to_html
#
# @example Command-line conversion
#   coradoc convert document.md -o output.html
#
# @example Using the developer API
#   html = Coradoc.convert(markdown_text, from: :markdown, to: :html)

require_relative 'coradoc/coradoc'

module Coradoc
  autoload :CLI, 'coradoc/cli'
  autoload :DocumentBuilder, 'coradoc/document_builder'
  autoload :DocumentManipulator, 'coradoc/document_manipulator'
  autoload :Visitor, 'coradoc/visitor'
  autoload :Serializer, 'coradoc/serializer/registry'
end
