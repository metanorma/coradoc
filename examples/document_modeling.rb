# frozen_string_literal: true

# Document modeling examples for Coradoc
#
# This file demonstrates how to work with the Coradoc document model.

require_relative '../lib/coradoc'

# Example 1: Accessing document structure
puts '=== Example 1: Accessing document structure ==='
input = <<~ASCIIDOC
  = Main Title

  == Section 1

  Paragraph in section 1.

  === Subsection 1.1

  Content in subsection.

  == Section 2

  Paragraph in section 2.
ASCIIDOC

doc = Coradoc.parse(input)

puts "Document title: #{doc.header.title}"
puts "Top-level sections: #{doc.sections.map { |s| s.title.content.first }.join(', ')}"

# Navigate to nested sections
section1 = doc.sections.first
puts "Section 1 subsections: #{section1.sections.map { |s| s.title.content.first }.join(', ')}"
puts

# Example 2: Working with paragraphs
puts '=== Example 2: Working with paragraphs ==='
input = <<~ASCIIDOC
  = Paragraph Examples

  First paragraph.

  Second paragraph with *bold* text.

  Third paragraph with a https://example.com[link].
ASCIIDOC

doc = Coradoc.parse(input)
section = doc.sections.first

section.paragraphs.each_with_index do |para, i|
  puts "Paragraph #{i + 1}:"
  para.content.each do |element|
    case element
    when Coradoc::Model::TextElement
      puts "  Text: #{element.text}"
    when Coradoc::Model::Inline::Bold
      puts "  Bold: #{element.content}"
    when Coradoc::Model::Inline::Link
      puts "  Link: #{element.path} [#{element.name}]"
    end
  end
end
puts

# Example 3: Working with lists
puts '=== Example 3: Working with lists ==='
input = <<~ASCIIDOC
  = List Examples

  * Item 1
  ** Item 1.1
  ** Item 1.2
  * Item 2

  . Step 1
  . Step 2
  . Step 3
ASCIIDOC

doc = Coradoc.parse(input)

# Find unordered list
unordered_list = doc.sections.first.blocks.find { |b| b.is_a?(Coradoc::Model::List::Unordered) }
if unordered_list
  puts "Unordered list has #{unordered_list.items.size} top-level items"
  unordered_list.items.each do |item|
    puts "  Item: #{item.content.first&.text}"
    # Check for nested lists
    puts "    Has nested list with #{item.nested_list.items.size} items" if item.nested_list
  end
end

# Find ordered list
ordered_list = doc.sections.first.blocks.find { |b| b.is_a?(Coradoc::Model::List::Ordered) }
puts "\nOrdered list has #{ordered_list.items.size} items" if ordered_list
puts

# Example 4: Working with tables
puts '=== Example 4: Working with tables ==='
input = <<~ASCIIDOC
  = Table Examples

  |===
  | Header 1 | Header 2 | Header 3

  | Cell 1.1 | Cell 1.2 | Cell 1.3
  | Cell 2.1 | Cell 2.2 | Cell 2.3
  |===
ASCIIDOC

doc = Coradoc.parse(input)

# Find table
table = doc.sections.first.blocks.find { |b| b.is_a?(Coradoc::Model::Table) }
if table
  puts "Table has #{table.rows.size} rows"
  table.rows.each_with_index do |row, i|
    cells_text = row.columns.map { |cell| cell.content.first&.text }.join(' | ')
    puts "  Row #{i + 1}: #{cells_text}"
  end
end
puts

# Example 5: Working with inline elements
puts '=== Example 5: Working with inline elements ==='
input = <<~ASCIIDOC
  = Inline Elements

  This paragraph has *bold*, _italic_, and `monospace` text.

  It also has a https://example.com[link to example] and <<anchor,cross-reference>>.

  [[anchor]]
  This section has an anchor.
ASCIIDOC

doc = Coradoc.parse(input)
paragraph = doc.sections.first.paragraphs.first

puts 'Inline element types in first paragraph:'
element_types = paragraph.content.map { |e| e.class.name }.uniq
element_types.each do |type|
  puts "  - #{type}"
end
puts

# Example 6: Working with attributes
puts '=== Example 6: Working with attributes ==='
input = <<~ASCIIDOC
  = Document Title
  :author: John Doe
  :version: 1.0

  == Section

  Content here.
ASCIIDOC

doc = Coradoc.parse(input)

puts 'Document attributes:'
doc.document_attributes.data.each do |key, value|
  puts "  #{key}: #{value}"
end
puts

# Example 7: Working with blocks
puts '=== Example 7: Working with blocks ==='
input = <<~ASCIIDOC
  = Block Examples

  [source,ruby]
  ----
  def example
    puts "Hello"
  end
  ----

  ____
  This is a quote block.
  It can span multiple lines.
  ____

  NOTE: This is a note admonition.
ASCIIDOC

doc = Coradoc.parse(input)

puts 'Block types in document:'
doc.sections.first.blocks.each do |block|
  puts "  - #{block.class.name}"
  puts "    Lines: #{block.lines.size}" if block.respond_to?(:lines)
  puts "    Content: #{block.content}" if block.respond_to?(:content)
end
puts

puts '=== All examples completed ==='
