# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Base do
  describe '.new' do
    it 'creates a base model with id' do
      model = described_class.new(id: 'test-id')

      expect(model.id).to eq('test-id')
    end

    it 'creates a base model with classes' do
      model = described_class.new(classes: %w[highlight important])

      expect(model.classes).to eq(%w[highlight important])
    end

    it 'creates a base model with attributes hash' do
      model = described_class.new(attributes: { 'data-role' => 'main' })

      expect(model.attributes).to eq({ 'data-role' => 'main' })
    end
  end

  describe '#to_h' do
    it 'returns a hash of attributes' do
      model = described_class.new(id: 'test', classes: %w[a b])

      hash = model.to_h

      expect(hash[:id]).to eq('test')
      expect(hash[:classes]).to eq(%w[a b])
    end
  end

  describe '#visit' do
    it 'traverses child attributes' do
      model = described_class.new(id: 'test')
      visited_ids = []

      model.visit do |elem, _phase|
        visited_ids << elem if elem.is_a?(String)
        elem
      end

      expect(visited_ids).to include('test')
    end
  end
end

RSpec.describe Coradoc::Markdown::Document do
  describe '.new' do
    it 'creates a document with blocks' do
      doc = described_class.new(
        blocks: [
          Coradoc::Markdown::Heading.new(level: 1, text: 'Title'),
          Coradoc::Markdown::Paragraph.new(text: 'Content')
        ]
      )

      expect(doc.blocks.length).to eq(2)
    end
  end

  describe '#[]' do
    it 'retrieves block by index' do
      heading = Coradoc::Markdown::Heading.new(level: 1, text: 'Title')
      doc = described_class.new(blocks: [heading])

      expect(doc[0]).to eq(heading)
    end
  end

  describe '#[]=' do
    it 'sets block by index' do
      doc = described_class.new(blocks: [])
      para = Coradoc::Markdown::Paragraph.new(text: 'New')

      doc[0] = para

      expect(doc[0]).to eq(para)
    end
  end

  describe '.from_ast' do
    it 'creates a document from elements array' do
      elements = [Coradoc::Markdown::Paragraph.new(text: 'Test')]

      doc = described_class.from_ast(elements)

      expect(doc.blocks).to eq(elements)
    end
  end
end

RSpec.describe Coradoc::Markdown::Heading do
  describe '.new' do
    it 'creates a heading with level and text' do
      heading = described_class.new(level: 2, text: 'Section Title')

      expect(heading.level).to eq(2)
      expect(heading.text).to eq('Section Title')
    end

    it 'defaults level to 1' do
      heading = described_class.new(text: 'Title')

      expect(heading.level).to eq(1)
    end
  end
end

RSpec.describe Coradoc::Markdown::Paragraph do
  describe '.new' do
    it 'creates a paragraph with text' do
      para = described_class.new(text: 'Paragraph content')

      expect(para.text).to eq('Paragraph content')
    end
  end
end

RSpec.describe Coradoc::Markdown::Text do
  describe '.new' do
    it 'creates text with content' do
      text = described_class.new(content: 'Plain text')

      expect(text.content).to eq('Plain text')
    end
  end
end

RSpec.describe Coradoc::Markdown::List do
  describe '.new' do
    it 'creates an unordered list' do
      list = described_class.new(
        ordered: false,
        items: [
          Coradoc::Markdown::ListItem.new(text: 'Item 1'),
          Coradoc::Markdown::ListItem.new(text: 'Item 2')
        ]
      )

      expect(list.ordered).to be false
      expect(list.items.length).to eq(2)
    end

    it 'creates an ordered list' do
      list = described_class.new(ordered: true, items: [])

      expect(list.ordered).to be true
    end

    it 'defaults to unordered' do
      list = described_class.new(items: [])

      expect(list.ordered).to be false
    end
  end
end

RSpec.describe Coradoc::Markdown::ListItem do
  describe '.new' do
    it 'creates a list item with text' do
      item = described_class.new(text: 'List item content')

      expect(item.text).to eq('List item content')
    end

    it 'creates a task list item' do
      item = described_class.new(text: 'Task', checked: true)

      expect(item.checked).to be true
    end

    it 'supports nested sublist' do
      sublist = Coradoc::Markdown::List.new(items: [])
      item = described_class.new(text: 'Parent', sublist: sublist)

      expect(item.sublist).to eq(sublist)
    end
  end
end

RSpec.describe Coradoc::Markdown::Blockquote do
  describe '.new' do
    it 'creates a blockquote with content' do
      quote = described_class.new(content: 'Quoted text')

      expect(quote.content).to eq('Quoted text')
    end
  end
end

RSpec.describe Coradoc::Markdown::CodeBlock do
  describe '.new' do
    it 'creates a code block with code' do
      block = described_class.new(code: "puts 'hello'")

      expect(block.code).to eq("puts 'hello'")
    end

    it 'creates a code block with language' do
      block = described_class.new(code: 'code', language: 'ruby')

      expect(block.language).to eq('ruby')
    end
  end
end

RSpec.describe Coradoc::Markdown::Code do
  describe '.new' do
    it 'creates inline code with text' do
      code = described_class.new(text: 'inline code')

      expect(code.text).to eq('inline code')
    end
  end
end

RSpec.describe Coradoc::Markdown::Emphasis do
  describe '.new' do
    it 'creates emphasis (italic) text' do
      em = described_class.new(text: 'italic text')

      expect(em.text).to eq('italic text')
    end
  end
end

RSpec.describe Coradoc::Markdown::Strong do
  describe '.new' do
    it 'creates strong (bold) text' do
      strong = described_class.new(text: 'bold text')

      expect(strong.text).to eq('bold text')
    end
  end
end

RSpec.describe Coradoc::Markdown::Link do
  describe '.new' do
    it 'creates a link with url and text' do
      link = described_class.new(text: 'Example', url: 'https://example.com')

      expect(link.text).to eq('Example')
      expect(link.url).to eq('https://example.com')
    end

    it 'creates a link with title' do
      link = described_class.new(text: 'Link', url: 'https://example.com', title: 'Example Site')

      expect(link.title).to eq('Example Site')
    end
  end
end

RSpec.describe Coradoc::Markdown::Image do
  describe '.new' do
    it 'creates an image with src and alt' do
      img = described_class.new(src: 'image.png', alt: 'An image')

      expect(img.src).to eq('image.png')
      expect(img.alt).to eq('An image')
    end

    it 'creates an image with title' do
      img = described_class.new(src: 'img.png', alt: 'Alt', title: 'Title')

      expect(img.title).to eq('Title')
    end
  end
end

RSpec.describe Coradoc::Markdown::Table do
  describe '.new' do
    it 'creates a table with headers and rows' do
      table = described_class.new(
        headers: ['Col 1', 'Col 2'],
        rows: ['Cell 1 | Cell 2', 'Cell 3 | Cell 4']
      )

      expect(table.headers).to eq(['Col 1', 'Col 2'])
      expect(table.rows.length).to eq(2)
    end

    it 'creates a table with alignments' do
      table = described_class.new(
        headers: %w[A B],
        alignments: %w[left center]
      )

      expect(table.alignments).to eq(%w[left center])
    end
  end
end

RSpec.describe Coradoc::Markdown::HorizontalRule do
  describe '.new' do
    it 'creates a horizontal rule' do
      rule = described_class.new

      expect(rule).to be_a(described_class)
    end
  end
end

RSpec.describe Coradoc::Markdown::Math do
  describe '.new' do
    it 'creates math content' do
      math = described_class.new(content: 'E = mc^2')

      expect(math.content).to eq('E = mc^2')
    end

    it 'creates inline math' do
      math = described_class.inline('x^2')

      expect(math.inline).to be true
      expect(math.content).to eq('x^2')
    end

    it 'creates block math' do
      math = described_class.block('y = mx + b')

      expect(math.inline).to be false
    end
  end

  describe '#inline?' do
    it 'returns true for inline math' do
      math = described_class.new(content: 'x', inline: true)

      expect(math.inline?).to be true
    end

    it 'returns false for block math' do
      math = described_class.new(content: 'x', inline: false)

      expect(math.inline?).to be false
    end
  end

  describe '#to_md' do
    it 'converts inline math to markdown' do
      math = described_class.new(content: 'x^2', inline: true)

      expect(math.to_md).to eq('$$x^2$$')
    end

    it 'converts block math to markdown' do
      math = described_class.new(content: 'y = mx + b', inline: false)

      expect(math.to_md).to eq("$$\ny = mx + b\n$$")
    end
  end
end

RSpec.describe Coradoc::Markdown::Extension do
  describe '.new' do
    it 'creates an extension with name and content' do
      ext = described_class.new(name: 'comment', content: 'Note text')

      expect(ext.name).to eq('comment')
      expect(ext.content).to eq('Note text')
    end

    it 'creates a TOC extension' do
      ext = described_class.toc(levels: '1-3')

      expect(ext.name).to eq('toc')
      expect(ext.options).to eq({ levels: '1-3' })
    end
  end

  describe '#self_closing?' do
    it 'returns true for extensions without content' do
      ext = described_class.new(name: 'toc')

      expect(ext.self_closing?).to be true
    end

    it 'returns false for extensions with content' do
      ext = described_class.new(name: 'comment', content: 'text')

      expect(ext.self_closing?).to be false
    end
  end
end

RSpec.describe Coradoc::Markdown::AttributeList do
  describe '.new' do
    it 'creates an attribute list with id and classes' do
      attr_list = described_class.new(id: 'intro', classes: ['highlight'])

      expect(attr_list.id).to eq('intro')
      expect(attr_list.classes).to eq(['highlight'])
    end

    it 'defaults classes to empty array' do
      attr_list = described_class.new

      expect(attr_list.classes).to eq([])
    end
  end

  describe '.parse' do
    it 'parses an IAL string' do
      attr_list = described_class.parse('{:.highlight #intro}')

      expect(attr_list.id).to eq('intro')
      expect(attr_list.classes).to include('highlight')
    end
  end

  describe '#to_md' do
    it 'converts to markdown IAL syntax' do
      attr_list = described_class.new(id: 'test', classes: ['cls'])

      expect(attr_list.to_md).to eq('{:#test .cls}')
    end
  end

  describe '#empty?' do
    it 'returns true when no attributes set' do
      attr_list = described_class.new

      expect(attr_list.empty?).to be true
    end

    it 'returns false when id is set' do
      attr_list = described_class.new(id: 'test')

      expect(attr_list.empty?).to be false
    end
  end
end
