# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Coradoc::Mirror::CoreModelToMirror do
  let(:registry) { Coradoc::Mirror.default_registry }
  let(:transformer) { described_class.new(registry: registry) }

  def make_section(title: 'Section', level: 1, children: [], id: nil)
    Coradoc::CoreModel::SectionElement.new(
      title: title,
      level: level,
      children: children,
      id: id
    )
  end

  def make_paragraph(text, id: nil)
    Coradoc::CoreModel::ParagraphBlock.new(
      content: text,
      id: id
    )
  end

  def make_document(title: 'Doc', children: [])
    Coradoc::CoreModel::DocumentElement.new(
      title: title,
      children: children
    )
  end

  describe '#call' do
    it 'transforms a simple document with title' do
      doc = make_document(title: 'My Document')
      result = transformer.call(doc)

      expect(result).to be_a(Coradoc::Mirror::Node::Document)
      expect(result.title).to eq('My Document')
    end

    it 'transforms a document with sections' do
      doc = make_document(title: 'Doc', children: [
                            make_section(title: 'Introduction', level: 1, children: [
                                           make_paragraph('Hello world')
                                         ])
                          ])
      result = transformer.call(doc)

      expect(result.content.length).to eq(1)
      section = result.content.first
      expect(section).to be_a(Coradoc::Mirror::Node::Section)
      expect(section.title).to eq('Introduction')
      expect(section.level).to eq(1)

      para = section.content.first
      expect(para).to be_a(Coradoc::Mirror::Node::Paragraph)
      expect(para.content.first.text).to eq('Hello world')
    end

    it 'produces valid JSON' do
      doc = make_document(title: 'Test', children: [
                            make_paragraph('Content')
                          ])
      result = transformer.call(doc)
      json = result.to_json

      parsed = JSON.parse(json)
      expect(parsed['type']).to eq('doc')
      expect(parsed['attrs']['title']).to eq('Test')
    end
  end

  describe 'block transformations' do
    it 'transforms source block' do
      block = Coradoc::CoreModel::SourceBlock.new(
        content: 'def hello; end',
        language: 'ruby'
      )
      doc = make_document(children: [block])
      result = transformer.call(doc)

      code = result.content.first
      expect(code).to be_a(Coradoc::Mirror::Node::CodeBlock)
      expect(code.language).to eq('ruby')
      expect(code.content.first.text).to eq('def hello; end')
    end

    it 'transforms quote block' do
      block = Coradoc::CoreModel::QuoteBlock.new(
        content: 'To be or not to be',
        attribution: 'Shakespeare'
      )
      doc = make_document(children: [block])
      result = transformer.call(doc)

      quote = result.content.first
      expect(quote).to be_a(Coradoc::Mirror::Node::Blockquote)
      expect(quote.attribution).to eq('Shakespeare')
    end

    it 'transforms example block' do
      block = Coradoc::CoreModel::ExampleBlock.new(
        content: 'Example content',
        title: 'Example 1'
      )
      doc = make_document(children: [block])
      result = transformer.call(doc)

      example = result.content.first
      expect(example).to be_a(Coradoc::Mirror::Node::Example)
      expect(example.title).to eq('Example 1')
    end

    it 'transforms sidebar block' do
      block = Coradoc::CoreModel::SidebarBlock.new(content: 'Side info')
      doc = make_document(children: [block])
      result = transformer.call(doc)

      sidebar = result.content.first
      expect(sidebar).to be_a(Coradoc::Mirror::Node::Sidebar)
    end

    it 'transforms open block' do
      block = Coradoc::CoreModel::OpenBlock.new(content: 'Open content')
      doc = make_document(children: [block])
      result = transformer.call(doc)

      open = result.content.first
      expect(open).to be_a(Coradoc::Mirror::Node::OpenBlock)
    end

    it 'transforms verse block' do
      block = Coradoc::CoreModel::VerseBlock.new(
        content: 'Roses are red',
        attribution: 'Anonymous'
      )
      doc = make_document(children: [block])
      result = transformer.call(doc)

      verse = result.content.first
      expect(verse).to be_a(Coradoc::Mirror::Node::Verse)
      expect(verse.attribution).to eq('Anonymous')
    end

    it 'transforms horizontal rule' do
      block = Coradoc::CoreModel::HorizontalRuleBlock.new
      doc = make_document(children: [block])
      result = transformer.call(doc)

      hr = result.content.first
      expect(hr).to be_a(Coradoc::Mirror::Node::HorizontalRule)
    end

    it 'skips comment blocks' do
      block = Coradoc::CoreModel::CommentBlock.new(content: 'Hidden')
      doc = make_document(children: [block])
      result = transformer.call(doc)

      expect(result.content).to be_empty
    end

    it 'skips reviewer blocks' do
      block = Coradoc::CoreModel::ReviewerBlock.new(content: 'Review')
      doc = make_document(children: [block])
      result = transformer.call(doc)

      expect(result.content).to be_empty
    end

    it 'transforms annotation / admonition block' do
      block = Coradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'note',
        content: 'This is a note'
      )
      doc = make_document(children: [block])
      result = transformer.call(doc)

      admonition = result.content.first
      expect(admonition).to be_a(Coradoc::Mirror::Node::Admonition)
      expect(admonition.admonition_type).to eq('note')
    end
  end

  describe 'list transformations' do
    it 'transforms unordered list' do
      list = Coradoc::CoreModel::ListBlock.new(
        marker_type: 'unordered',
        items: [
          Coradoc::CoreModel::ListItem.new(content: 'First'),
          Coradoc::CoreModel::ListItem.new(content: 'Second')
        ]
      )
      doc = make_document(children: [list])
      result = transformer.call(doc)

      ul = result.content.first
      expect(ul).to be_a(Coradoc::Mirror::Node::BulletList)
      expect(ul.content.length).to eq(2)
      expect(ul.content.first).to be_a(Coradoc::Mirror::Node::ListItem)
      expect(ul.content.first.content.first.text).to eq('First')
    end

    it 'transforms ordered list' do
      list = Coradoc::CoreModel::ListBlock.new(
        marker_type: 'ordered',
        items: [
          Coradoc::CoreModel::ListItem.new(content: 'Step 1'),
          Coradoc::CoreModel::ListItem.new(content: 'Step 2')
        ]
      )
      doc = make_document(children: [list])
      result = transformer.call(doc)

      ol = result.content.first
      expect(ol).to be_a(Coradoc::Mirror::Node::OrderedList)
      expect(ol.content.length).to eq(2)
    end

    it 'transforms list with nested list' do
      inner = Coradoc::CoreModel::ListBlock.new(
        marker_type: 'unordered',
        items: [Coradoc::CoreModel::ListItem.new(content: 'Nested')]
      )
      list = Coradoc::CoreModel::ListBlock.new(
        marker_type: 'unordered',
        items: [
          Coradoc::CoreModel::ListItem.new(
            content: 'Parent',
            nested_list: inner
          )
        ]
      )
      doc = make_document(children: [list])
      result = transformer.call(doc)

      ul = result.content.first
      item = ul.content.first
      nested = item.content.last
      expect(nested).to be_a(Coradoc::Mirror::Node::BulletList)
    end

    it 'transforms definition list' do
      dl = Coradoc::CoreModel::DefinitionList.new(
        items: [
          Coradoc::CoreModel::DefinitionItem.new(
            term: 'API',
            definitions: ['Application Programming Interface']
          )
        ]
      )
      doc = make_document(children: [dl])
      result = transformer.call(doc)

      mirror_dl = result.content.first
      expect(mirror_dl).to be_a(Coradoc::Mirror::Node::DefinitionList)
      expect(mirror_dl.content.length).to eq(2) # term + description
      expect(mirror_dl.content.first).to be_a(Coradoc::Mirror::Node::DefinitionTerm)
      expect(mirror_dl.content.last).to be_a(Coradoc::Mirror::Node::DefinitionDescription)
    end
  end

  describe 'table transformation' do
    it 'transforms table with header and body' do
      table = Coradoc::CoreModel::Table.new(
        title: 'Data',
        rows: [
          Coradoc::CoreModel::TableRow.new(
            header: true,
            cells: [
              Coradoc::CoreModel::TableCell.new(content: 'Name', header: true),
              Coradoc::CoreModel::TableCell.new(content: 'Value', header: true)
            ]
          ),
          Coradoc::CoreModel::TableRow.new(
            cells: [
              Coradoc::CoreModel::TableCell.new(content: 'Foo'),
              Coradoc::CoreModel::TableCell.new(content: 'Bar')
            ]
          )
        ]
      )
      doc = make_document(children: [table])
      result = transformer.call(doc)

      mirror_table = result.content.first
      expect(mirror_table).to be_a(Coradoc::Mirror::Node::Table)
      expect(mirror_table.title).to eq('Data')
      expect(mirror_table.content.length).to eq(2) # head + body

      head = mirror_table.content.first
      expect(head).to be_a(Coradoc::Mirror::Node::TableHead)
      body = mirror_table.content.last
      expect(body).to be_a(Coradoc::Mirror::Node::TableBody)
    end
  end

  describe 'image transformation' do
    it 'transforms image with all attributes' do
      image = Coradoc::CoreModel::Image.new(
        src: 'images/diagram.png',
        alt: 'Diagram',
        caption: 'Figure 1',
        width: '800px'
      )
      doc = make_document(children: [image])
      result = transformer.call(doc)

      mirror_img = result.content.first
      expect(mirror_img).to be_a(Coradoc::Mirror::Node::Image)
      expect(mirror_img.src).to eq('images/diagram.png')
      expect(mirror_img.alt).to eq('Diagram')
      expect(mirror_img.caption).to eq('Figure 1')
      expect(mirror_img.width).to eq('800px')
    end
  end

  describe 'inline element transformation' do
    it 'transforms bold text' do
      bold = Coradoc::CoreModel::BoldElement.new(content: 'important')
      para = Coradoc::CoreModel::ParagraphBlock.new(children: [bold])
      doc = make_document(children: [para])
      result = transformer.call(doc)

      para_node = result.content.first
      text_node = para_node.content.first
      expect(text_node).to be_a(Coradoc::Mirror::Node::Text)
      expect(text_node.text).to eq('important')
      expect(text_node.marks.first).to be_a(Coradoc::Mirror::Mark::Bold)
    end

    it 'transforms italic text' do
      italic = Coradoc::CoreModel::ItalicElement.new(content: 'emphasis')
      para = Coradoc::CoreModel::ParagraphBlock.new(children: [italic])
      doc = make_document(children: [para])
      result = transformer.call(doc)

      text_node = result.content.first.content.first
      expect(text_node.marks.first).to be_a(Coradoc::Mirror::Mark::Italic)
    end

    it 'transforms monospace text' do
      mono = Coradoc::CoreModel::MonospaceElement.new(content: 'code')
      para = Coradoc::CoreModel::ParagraphBlock.new(children: [mono])
      doc = make_document(children: [para])
      result = transformer.call(doc)

      text_node = result.content.first.content.first
      expect(text_node.marks.first).to be_a(Coradoc::Mirror::Mark::Monospace)
    end

    it 'transforms link' do
      link = Coradoc::CoreModel::LinkElement.new(
        content: 'Click here',
        target: 'https://example.com'
      )
      para = Coradoc::CoreModel::ParagraphBlock.new(children: [link])
      doc = make_document(children: [para])
      result = transformer.call(doc)

      text_node = result.content.first.content.first
      expect(text_node.text).to eq('Click here')
      expect(text_node.marks.first).to be_a(Coradoc::Mirror::Mark::Link)
      expect(text_node.marks.first.href).to eq('https://example.com')
    end

    it 'transforms cross-reference' do
      xref = Coradoc::CoreModel::CrossReferenceElement.new(
        content: 'Section 1',
        target: 'section-1'
      )
      para = Coradoc::CoreModel::ParagraphBlock.new(children: [xref])
      doc = make_document(children: [para])
      result = transformer.call(doc)

      text_node = result.content.first.content.first
      expect(text_node.marks.first).to be_a(Coradoc::Mirror::Mark::CrossReference)
      expect(text_node.marks.first.target).to eq('section-1')
    end

    it 'transforms subscript and superscript' do
      sub = Coradoc::CoreModel::SubscriptElement.new(content: '2')
      sup = Coradoc::CoreModel::SuperscriptElement.new(content: 'nd')
      para = Coradoc::CoreModel::ParagraphBlock.new(children: [sub, sup])
      doc = make_document(children: [para])
      result = transformer.call(doc)

      nodes = result.content.first.content
      expect(nodes[0].marks.first).to be_a(Coradoc::Mirror::Mark::Subscript)
      expect(nodes[1].marks.first).to be_a(Coradoc::Mirror::Mark::Superscript)
    end

    it 'transforms highlight' do
      highlight = Coradoc::CoreModel::HighlightElement.new(content: 'noted')
      para = Coradoc::CoreModel::ParagraphBlock.new(children: [highlight])
      doc = make_document(children: [para])
      result = transformer.call(doc)

      text_node = result.content.first.content.first
      expect(text_node.marks.first).to be_a(Coradoc::Mirror::Mark::Highlight)
    end

    it 'transforms text content' do
      text = Coradoc::CoreModel::TextContent.new(text: 'plain text')
      para = Coradoc::CoreModel::ParagraphBlock.new(children: [text])
      doc = make_document(children: [para])
      result = transformer.call(doc)

      text_node = result.content.first.content.first
      expect(text_node.text).to eq('plain text')
      expect(text_node.marks).to be_empty
    end
  end

  describe 'bibliography transformation' do
    it 'transforms bibliography with entries' do
      bib = Coradoc::CoreModel::Bibliography.new(
        title: 'References',
        entries: [
          Coradoc::CoreModel::BibliographyEntry.new(
            anchor_name: 'ISO712',
            document_id: 'ISO 712',
            ref_text: 'Cereals and cereal products'
          )
        ]
      )
      doc = make_document(children: [bib])
      result = transformer.call(doc)

      mirror_bib = result.content.first
      expect(mirror_bib).to be_a(Coradoc::Mirror::Node::Bibliography)
      expect(mirror_bib.title).to eq('References')
      entry = mirror_bib.content.first
      expect(entry).to be_a(Coradoc::Mirror::Node::BibliographyEntry)
      expect(entry.document_id).to eq('ISO 712')
    end
  end

  describe 'footnote transformation' do
    it 'transforms footnote and collects at document end' do
      fn = Coradoc::CoreModel::Footnote.new(id: 'fn1', content: 'A footnote.')
      para = make_paragraph('Text with footnote')
      doc = make_document(children: [para, fn])
      result = transformer.call(doc)

      # Last content should be footnotes block
      footnotes = result.content.last
      expect(footnotes).to be_a(Coradoc::Mirror::Node::Footnotes)
      entry = footnotes.content.first
      expect(entry).to be_a(Coradoc::Mirror::Node::FootnoteEntry)
      expect(entry.number).to eq(1)
    end
  end

  describe 'kitchen sink' do
    it 'transforms a complex document with multiple element types' do
      doc = make_document(title: 'Kitchen Sink', children: [
                            make_section(title: 'Overview', level: 1, children: [
                                           make_paragraph('Welcome to the test document.'),
                                           Coradoc::CoreModel::SourceBlock.new(
                                             content: "puts 'hello'",
                                             language: 'ruby'
                                           ),
                                           Coradoc::CoreModel::ListBlock.new(
                                             marker_type: 'unordered',
                                             items: [
                                               Coradoc::CoreModel::ListItem.new(content: 'Item 1'),
                                               Coradoc::CoreModel::ListItem.new(content: 'Item 2')
                                             ]
                                           )
                                         ]),
                            make_section(title: 'Details', level: 2, children: [
                                           Coradoc::CoreModel::AnnotationBlock.new(
                                             annotation_type: 'warning',
                                             content: 'Be careful!'
                                           ),
                                           Coradoc::CoreModel::Image.new(
                                             src: 'diagram.png',
                                             alt: 'Architecture'
                                           )
                                         ])
                          ])

      result = transformer.call(doc)
      json = result.to_json(pretty: true)
      parsed = JSON.parse(json)

      # Verify structure
      expect(parsed['type']).to eq('doc')
      expect(parsed['attrs']['title']).to eq('Kitchen Sink')
      expect(parsed['content'].length).to eq(2)

      # Section 1
      s1 = parsed['content'][0]
      expect(s1['type']).to eq('section')
      expect(s1['attrs']['title']).to eq('Overview')
      expect(s1['content'].length).to eq(3)

      # Section 2
      s2 = parsed['content'][1]
      expect(s2['type']).to eq('section')
      expect(s2['attrs']['title']).to eq('Details')
    end
  end
end
