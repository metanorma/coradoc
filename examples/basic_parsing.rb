# frozen_string_literal: true

# Basic parsing examples for Coradoc
#
# This file demonstrates how to parse AsciiDoc documents using Coradoc.

require_relative '../lib/coradoc'

# Helper method to find first actual Section
def find_first_section(doc)
  doc.sections.find { |s| s.is_a?(Coradoc::Model::Section) }
end

# Example 1: Parse a simple document
puts '=== Example 1: Parse a simple document ==='
input = <<~ASCIIDOC
  = Hello World

  This is a paragraph.

  == Section 1

  This is content in section 1.
ASCIIDOC

doc = Coradoc.parse(input)
puts "Document title: #{doc.header.title}"
puts "Number of sections: #{doc.sections.size}"
section = find_first_section(doc)
puts "First section title: #{section.title.content}" if section
puts

# Example 2: Parse from file
puts '=== Example 2: Parse from file ==='
temp_file = '/tmp/coradoc_example.adoc'
File.write(temp_file, <<~ASCIIDOC)
  = Document Title
  Author Name <author@example.com>

  == Introduction

  This is the introduction paragraph.

  * List item 1
  * List item 2
  * List item 3
ASCIIDOC

doc = Coradoc.parse_file(temp_file)
puts "Document title: #{doc.header.title}"
puts "Author: #{doc.header.author&.first&.name}"
section = find_first_section(doc)
if section
  paragraphs = section.contents.select { |c| c.is_a?(Coradoc::Model::Paragraph) }
  lists = section.contents.select { |c| c.is_a?(Coradoc::Model::List::Core) }
  puts "Number of paragraphs: #{paragraphs.size}"
  puts "Number of lists: #{lists.size}"
end
puts

# Example 3: Parse with inline formatting
puts '=== Example 3: Parse with inline formatting ==='
input = <<~ASCIIDOC
  = Formatting Examples

  This has *bold text* and _italic text_.

  This has `monospace text` and a https://example.com[link].
ASCIIDOC

doc = Coradoc.parse(input)
paragraph = doc.sections.find { |s| s.is_a?(Coradoc::Model::Paragraph) }
if paragraph
  puts "Paragraph has #{paragraph.content.size} content elements"
  paragraph.content.each do |element|
    puts "  - #{element.class.name}"
  end
end
puts

# Example 4: Parse lists
puts '=== Example 4: Parse lists ==='
input = <<~ASCIIDOC
  = Lists

  * Unordered item 1
  ** Nested item
  * Unordered item 2

  . Ordered item 1
  . Ordered item 2
  . Ordered item 3

  [horizontal]
  Term 1:: Definition 1
  Term 2:: Definition 2
ASCIIDOC

doc = Coradoc.parse(input)
lists = doc.sections.select { |s| s.is_a?(Coradoc::Model::List::Core) }
puts "Number of lists: #{lists.size}"
lists.each_with_index do |list, i|
  puts "  List #{i + 1}: #{list.class.name} with #{list.items.size} items"
end
puts

# Example 5: Parse blocks
puts '=== Example 5: Parse blocks ==='
input = <<~ASCIIDOC
  = Blocks

  [source,ruby]
  ----
  def hello
    puts "Hello, World!"
  end
  ----

  ____
  Quoted text block.
  ____

  NOTE: This is a note admonition.
ASCIIDOC

doc = Coradoc.parse(input)
section = find_first_section(doc)
section&.contents&.each do |block|
  puts "Block type: #{block.class.name}"
end
puts

# Cleanup
File.delete(temp_file) if File.exist?(temp_file)

puts '=== All examples completed ==='
