# frozen_string_literal: true

# Serialization examples for Coradoc
#
# This file demonstrates how to serialize Coradoc document models to AsciiDoc.

require_relative '../lib/coradoc'

# Example 1: Basic serialization
puts '=== Example 1: Basic serialization ==='
input = <<~ASCIIDOC
  = Document Title

  == Section 1

  This is a paragraph.
ASCIIDOC

doc = Coradoc.parse(input)
output = doc.to_adoc

puts 'Serialized output:'
puts output
puts

# Example 2: Serialize individual elements
puts '=== Example 2: Serialize individual elements ==='

# Serialize a paragraph
paragraph = Coradoc::Model::Paragraph.new
paragraph.content = [
  Coradoc::Model::TextElement.new('This is a paragraph with '),
  Coradoc::Model::Inline::Bold.new(content: 'bold text')
]
puts 'Paragraph:'
puts paragraph.to_adoc
puts

# Serialize a section
section = Coradoc::Model::Section.new
section.title = Coradoc::Model::Title.new
section.title.level_int = 2
section.title.content = ['Custom Section']
para = Coradoc::Model::Paragraph.new
para.content = [Coradoc::Model::TextElement.new('Section content')]
section.blocks = [para]
puts 'Section:'
puts section.to_adoc
puts

# Example 3: Serialize lists
puts '=== Example 3: Serialize lists ==='

# Unordered list
list = Coradoc::Model::List::Unordered.new
item1 = Coradoc::Model::ListItem.new
item1.content = [Coradoc::Model::TextElement.new('First item')]
list.items << item1

item2 = Coradoc::Model::ListItem.new
item2.content = [Coradoc::Model::TextElement.new('Second item')]
list.items << item2

puts 'Unordered list:'
puts list.to_adoc
puts

# Ordered list
ordered = Coradoc::Model::List::Ordered.new
item = Coradoc::Model::ListItem.new
item.content = [Coradoc::Model::TextElement.new('Step one')]
ordered.items << item

item = Coradoc::Model::ListItem.new
item.content = [Coradoc::Model::TextElement.new('Step two')]
ordered.items << item

puts 'Ordered list:'
puts ordered.to_adoc
puts

# Example 4: Serialize tables
puts '=== Example 4: Serialize tables ==='

table = Coradoc::Model::Table.new

# Add header row
header_row = Coradoc::Model::TableRow.new
%w[Name Age City].each do |header_text|
  cell = Coradoc::Model::TableCell.new
  cell.content = [Coradoc::Model::TextElement.new(header_text)]
  header_row.columns << cell
end
table.rows << header_row

# Add data row
data_row = Coradoc::Model::TableRow.new
%w[Alice 25 NYC].each do |cell_text|
  cell = Coradoc::Model::TableCell.new
  cell.content = [Coradoc::Model::TextElement.new(cell_text)]
  data_row.columns << cell
end
table.rows << data_row

puts 'Table:'
puts table.to_adoc
puts

# Example 5: Serialize blocks
puts '=== Example 5: Serialize blocks ==='

# Listing block
listing = Coradoc::Model::Block::Listing.new
listing.lines = ['def hello', "  puts 'Hello, World!'", 'end']
listing.attributes = Coradoc::Model::AttributeList.new
listing.attributes.add_positional('ruby')
puts 'Listing block:'
puts listing.to_adoc
puts

# Quote block
quote = Coradoc::Model::Block::Quote.new
quote.lines = ['This is a quote.', 'It spans multiple lines.']
puts 'Quote block:'
puts quote.to_adoc
puts

# Example 6: Serialize inline elements
puts '=== Example 6: Serialize inline elements ==='

# Create paragraph with various inline elements
paragraph = Coradoc::Model::Paragraph.new
paragraph.content = [
  Coradoc::Model::TextElement.new('Text with '),
  Coradoc::Model::Inline::Bold.new(content: 'bold'),
  Coradoc::Model::TextElement.new(', '),
  Coradoc::Model::Inline::Italic.new(content: 'italic'),
  Coradoc::Model::TextElement.new(', and '),
  Coradoc::Model::Inline::Monospace.new(content: 'monospace'),
  Coradoc::Model::TextElement.new(' text.')
]

puts 'Paragraph with inline elements:'
puts paragraph.to_adoc
puts

# Link
link = Coradoc::Model::Inline::Link.new
link.path = 'https://example.com'
link.name = 'Example Site'
puts 'Link:'
puts "#{link.to_adoc}\n"
puts

# Anchor
anchor = Coradoc::Model::Inline::Anchor.new
anchor.id = 'section1'
puts 'Anchor:'
puts "#{anchor.to_adoc}\n"
puts

# Example 7: Round-trip preservation
puts '=== Example 7: Round-trip preservation ==='
original = <<~ASCIIDOC
  = Document Title

  == Section One

  This is a paragraph with *bold* and _italic_ text.

  * List item 1
  * List item 2
ASCIIDOC

# Parse
doc1 = Coradoc.parse(original)
# Serialize
serialized = doc1.to_adoc
# Parse again
doc2 = Coradoc.parse(serialized)

puts "Original document title: #{doc1.header.title}"
puts "Re-parsed document title: #{doc2.header.title}"

# Both should have the same structure
puts "Original sections: #{doc1.sections.size}"
puts "Re-parsed sections: #{doc2.sections.size}"
puts

# Example 8: Using Coradoc.convert
puts '=== Example 8: Using Coradoc.convert ==='
doc = Coradoc.parse("= Test\n\nContent")

# Convert to AsciiDoc (same as to_adoc)
output = Coradoc.convert(doc, to: :adoc)
puts 'Converted output:'
puts output
puts

puts '=== All examples completed ==='
