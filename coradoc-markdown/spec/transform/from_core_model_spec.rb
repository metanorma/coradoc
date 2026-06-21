# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Transform::FromCoreModel do
  describe '.transform' do
    subject(:transform) { described_class.transform(core_model) }

    context 'with DocumentElement (document)' do
      let(:core_model) do
        Coradoc::CoreModel::DocumentElement.new(
          id: 'doc-1',
          title: 'Document Title',
          children: [
            Coradoc::CoreModel::Block.new(
              element_type: 'paragraph',
              content: 'Introduction paragraph'
            )
          ]
        )
      end

      it 'transforms to Markdown::Document' do
        expect(transform).to be_a(Coradoc::Markdown::Document)
        expect(transform.id).to eq('doc-1')
        expect(transform.blocks).to be_an(Array)
      end
    end

    context 'with SectionElement (section)' do
      let(:core_model) do
        Coradoc::CoreModel::SectionElement.new(
          level: 2,
          title: 'Section Title',
          children: []
        )
      end

      it 'transforms to Markdown::Heading' do
        heading = transform.is_a?(Array) ? transform.first : transform
        expect(heading).to be_a(Coradoc::Markdown::Heading)
        expect(heading.level).to eq(2)
        expect(heading.text).to eq('Section Title')
      end
    end

    context 'with Block (paragraph)' do
      let(:core_model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'paragraph',
          content: 'This is a paragraph.'
        )
      end

      it 'transforms to Markdown::Paragraph' do
        expect(transform).to be_a(Coradoc::Markdown::Paragraph)
        expect(transform.text).to eq('This is a paragraph.')
      end
    end

    context 'with Block (code block)' do
      let(:core_model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'block',
          delimiter_type: '```',
          content: "puts 'hello'",
          language: 'ruby'
        )
      end

      it 'transforms to Markdown::CodeBlock' do
        expect(transform).to be_a(Coradoc::Markdown::CodeBlock)
        expect(transform.code).to eq("puts 'hello'")
        expect(transform.language).to eq('ruby')
      end
    end

    context 'with SourceBlock containing callouts' do
      let(:core_model) do
        Coradoc::CoreModel::SourceBlock.new(
          content: "get '/hi' do <1>\nputs \"hello\" <2>",
          language: 'ruby',
          callouts: [
            Coradoc::CoreModel::Callout.new(index: 1, content: 'Returns hello world'),
            Coradoc::CoreModel::Callout.new(index: 2, content: 'Prints greeting')
          ]
        )
      end

      it 'returns [CodeBlock, List] with markers stripped from code' do
        expect(transform).to be_an(Array)
        expect(transform.size).to eq(2)

        code_block, list = transform
        expect(code_block).to be_a(Coradoc::Markdown::CodeBlock)
        expect(code_block.code).to eq("get '/hi' do\nputs \"hello\"")
        expect(code_block.language).to eq('ruby')

        expect(list).to be_a(Coradoc::Markdown::List)
        expect(list.ordered).to be(true)
        expect(list.items.map(&:text)).to eq(['Returns hello world', 'Prints greeting'])
      end
    end

    context 'with SourceBlock without callouts but literal <N> in code' do
      let(:core_model) do
        Coradoc::CoreModel::SourceBlock.new(
          content: 'x = 1 if y < 1',
          language: 'ruby'
        )
      end

      it 'leaves literal <N> intact' do
        expect(transform).to be_a(Coradoc::Markdown::CodeBlock)
        expect(transform.code).to eq('x = 1 if y < 1')
      end
    end

    context 'with two SourceBlocks each carrying their own callouts' do
      let(:core_model) do
        [
          Coradoc::CoreModel::SourceBlock.new(
            content: "alpha <1>\nbeta",
            language: 'ruby',
            callouts: [Coradoc::CoreModel::Callout.new(index: 1, content: 'first block note')]
          ),
          Coradoc::CoreModel::SourceBlock.new(
            content: "gamma <1>\ndelta",
            language: 'python',
            callouts: [Coradoc::CoreModel::Callout.new(index: 1, content: 'second block note')]
          )
        ]
      end

      it 'pairs each code block with its own callout list' do
        expect(transform).to be_an(Array)
        expect(transform.length).to eq(4)

        first_code, first_list, second_code, second_list = transform
        expect(first_code.code).to eq("alpha\nbeta")
        expect(first_code.language).to eq('ruby')
        expect(first_list.items.first.text).to eq('first block note')

        expect(second_code.code).to eq("gamma\ndelta")
        expect(second_code.language).to eq('python')
        expect(second_list.items.first.text).to eq('second block note')
      end
    end

    context 'with Block (blockquote)' do
      let(:core_model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'block',
          delimiter_type: '>',
          content: 'Quoted content'
        )
      end

      it 'transforms to Markdown::Blockquote' do
        expect(transform).to be_a(Coradoc::Markdown::Blockquote)
        expect(transform.content).to eq('Quoted content')
      end
    end

    context 'with Block (horizontal rule)' do
      let(:core_model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'block',
          delimiter_type: '---'
        )
      end

      it 'transforms to Markdown::HorizontalRule' do
        expect(transform).to be_a(Coradoc::Markdown::HorizontalRule)
      end
    end

    context 'with ListBlock (unordered)' do
      let(:core_model) do
        Coradoc::CoreModel::ListBlock.new(
          marker_type: 'unordered',
          items: [
            Coradoc::CoreModel::ListItem.new(content: 'First item', marker: '*'),
            Coradoc::CoreModel::ListItem.new(content: 'Second item', marker: '*')
          ]
        )
      end

      it 'transforms to Markdown::List with unordered type' do
        expect(transform).to be_a(Coradoc::Markdown::List)
        expect(transform.ordered).to be false
        expect(transform.items.length).to eq(2)
        expect(transform.items.first.text).to eq('First item')
      end
    end

    context 'with ListBlock (ordered)' do
      let(:core_model) do
        Coradoc::CoreModel::ListBlock.new(
          marker_type: 'ordered',
          items: [
            Coradoc::CoreModel::ListItem.new(content: 'First', marker: '1.')
          ]
        )
      end

      it 'transforms to Markdown::List with ordered type' do
        expect(transform).to be_a(Coradoc::Markdown::List)
        expect(transform.ordered).to be true
      end
    end

    context 'with Table' do
      let(:core_model) do
        Coradoc::CoreModel::Table.new(
          rows: [
            Coradoc::CoreModel::TableRow.new(
              cells: [
                Coradoc::CoreModel::TableCell.new(content: 'Header 1', header: true),
                Coradoc::CoreModel::TableCell.new(content: 'Header 2', header: true)
              ]
            ),
            Coradoc::CoreModel::TableRow.new(
              cells: [
                Coradoc::CoreModel::TableCell.new(content: 'Cell 1', header: false),
                Coradoc::CoreModel::TableCell.new(content: 'Cell 2', header: false)
              ]
            )
          ]
        )
      end

      it 'transforms to Markdown::Table with headers and rows' do
        expect(transform).to be_a(Coradoc::Markdown::Table)
        expect(transform.headers).to eq(['Header 1', 'Header 2'])
        expect(transform.rows.length).to eq(1)
        expect(transform.rows.first).to eq('Cell 1 | Cell 2')
      end
    end

    context 'with Table containing inline elements in cells' do
      let(:core_model) do
        Coradoc::CoreModel::Table.new(
          rows: [
            Coradoc::CoreModel::TableRow.new(
              cells: [
                Coradoc::CoreModel::TableCell.new(
                  content: 'bold cell',
                  children: [
                    Coradoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'bold cell')
                  ]
                )
              ]
            )
          ]
        )
      end

      it 'uses flat_text for cell content' do
        expect(transform).to be_a(Coradoc::Markdown::Table)
        expect(transform.rows.first).to eq('bold cell')
      end
    end

    context 'with Image' do
      let(:core_model) do
        Coradoc::CoreModel::Image.new(
          src: 'image.png',
          alt: 'An image'
        )
      end

      it 'transforms to Markdown::Image' do
        expect(transform).to be_a(Coradoc::Markdown::Image)
        expect(transform.src).to eq('image.png')
        expect(transform.alt).to eq('An image')
      end
    end

    context 'with InlineElement (link)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'link',
          target: 'https://example.com',
          content: 'Click here'
        )
      end

      it 'transforms to Markdown::Link' do
        expect(transform).to be_a(Coradoc::Markdown::Link)
        expect(transform.url).to eq('https://example.com')
        expect(transform.text).to eq('Click here')
      end
    end

    context 'with InlineElement (bold)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'bold',
          content: 'bold text'
        )
      end

      it 'transforms to Markdown::Strong' do
        expect(transform).to be_a(Coradoc::Markdown::Strong)
        expect(transform.text).to eq('bold text')
      end
    end

    context 'with InlineElement (italic)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'italic',
          content: 'italic text'
        )
      end

      it 'transforms to Markdown::Emphasis' do
        expect(transform).to be_a(Coradoc::Markdown::Emphasis)
        expect(transform.text).to eq('italic text')
      end
    end

    context 'with InlineElement (monospace)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'monospace',
          content: 'code'
        )
      end

      it 'transforms to Markdown::Code' do
        expect(transform).to be_a(Coradoc::Markdown::Code)
        expect(transform.text).to eq('code')
      end
    end

    context 'with InlineElement (unknown type)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'unknown',
          content: 'some text'
        )
      end

      it 'returns the content as string' do
        expect(transform).to eq('some text')
      end
    end

    context 'with InlineElement (highlight)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'highlight',
          content: 'highlighted'
        )
      end

      it 'transforms to Markdown::Highlight' do
        expect(transform).to be_a(Coradoc::Markdown::Highlight)
        expect(transform.text).to eq('highlighted')
      end
    end

    context 'with InlineElement (strikethrough)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'strikethrough',
          content: 'deleted'
        )
      end

      it 'transforms to Markdown::Strikethrough' do
        expect(transform).to be_a(Coradoc::Markdown::Strikethrough)
        expect(transform.text).to eq('deleted')
      end
    end

    context 'with InlineElement (subscript)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'subscript',
          content: '2'
        )
      end

      it 'returns Subscript model' do
        expect(transform).to be_a(Coradoc::Markdown::Subscript)
        expect(transform.text).to eq('2')
      end
    end

    context 'with InlineElement (superscript)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'superscript',
          content: '2'
        )
      end

      it 'returns Superscript model' do
        expect(transform).to be_a(Coradoc::Markdown::Superscript)
        expect(transform.text).to eq('2')
      end
    end

    context 'with InlineElement (underline)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'underline',
          content: 'underlined'
        )
      end

      it 'returns Underline model' do
        expect(transform).to be_a(Coradoc::Markdown::Underline)
        expect(transform.text).to eq('underlined')
      end
    end

    context 'with InlineElement (xref)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'xref',
          content: 'Section 1',
          target: 'section_1'
        )
      end

      it 'returns CrossReference model' do
        expect(transform).to be_a(Coradoc::Markdown::CrossReference)
        expect(transform.text).to eq('Section 1')
        expect(transform.target).to eq('section_1')
      end
    end

    context 'with Array' do
      let(:core_model) do
        [
          Coradoc::CoreModel::Block.new(
            element_type: 'paragraph',
            content: 'Para 1'
          ),
          Coradoc::CoreModel::Block.new(
            element_type: 'paragraph',
            content: 'Para 2'
          )
        ]
      end

      it 'transforms each element' do
        expect(transform).to be_an(Array)
        expect(transform.length).to eq(2)
        expect(transform.first).to be_a(Coradoc::Markdown::Paragraph)
        expect(transform.last).to be_a(Coradoc::Markdown::Paragraph)
      end
    end

    context 'with unknown type' do
      let(:core_model) { 'plain string' }

      it 'returns the value unchanged' do
        expect(transform).to eq('plain string')
      end
    end

    context 'with AnnotationBlock' do
      let(:core_model) { Coradoc::CoreModel::AnnotationBlock.new(annotation_type: 'NOTE', content: 'Be careful') }

      it 'produces an Admonition preserving type and content' do
        expect(transform).to be_a(Coradoc::Markdown::Admonition)
        expect(transform.admonition_type).to eq('note')
        expect(transform.content).to include('Be careful')
      end
    end

    context 'with AnnotationBlock containing inline children' do
      let(:core_model) do
        bold = Coradoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'important')
        Coradoc::CoreModel::AnnotationBlock.new(
          annotation_type: 'WARNING',
          content: 'This is important',
          children: ['This is ', bold]
        )
      end

      it 'flattens inline children to plain text in admonition output' do
        expect(transform).to be_a(Coradoc::Markdown::Admonition)
        expect(transform.admonition_type).to eq('warning')
        expect(transform.content).to include('This is important')
      end
    end

    context 'with Term' do
      let(:core_model) { Coradoc::CoreModel::Term.new(text: 'API', type: 'acronym') }

      it 'produces a Strong element' do
        expect(transform).to be_a(Coradoc::Markdown::Strong)
        expect(transform.text).to eq('API')
      end
    end

    context 'with Bibliography' do
      let(:core_model) do
        Coradoc::CoreModel::Bibliography.new(
          title: 'References',
          entries: [
            Coradoc::CoreModel::BibliographyEntry.new(
              anchor_name: 'ISO712', document_id: 'ISO 712',
              ref_text: 'Cereals.'
            )
          ]
        )
      end

      it 'produces a Document with heading and entries' do
        expect(transform).to be_a(Coradoc::Markdown::Document)
      end
    end

    context 'with BibliographyEntry' do
      let(:core_model) do
        Coradoc::CoreModel::BibliographyEntry.new(
          document_id: 'ISO 712', ref_text: 'Cereals.'
        )
      end

      it 'produces a Paragraph with label and text' do
        expect(transform).to be_a(Coradoc::Markdown::Paragraph)
        expect(transform.text).to include('ISO 712')
      end
    end

    context 'with BibliographyEntry containing formatting' do
      let(:core_model) do
        Coradoc::CoreModel::BibliographyEntry.new(
          document_id: 'ISO 712', ref_text: 'The _Cereals_ are *very* important. [smallcap]#TEXT#. footnote:[This is a footnote]'
        )
      end

      it 'strips AsciiDoc markers and converts to Markdown' do
        expect(transform).to be_a(Coradoc::Markdown::Paragraph)
        expect(transform.text).to include('The *Cereals* are **very** important. TEXT. ^[This is a footnote]')
      end
    end

    context 'with TocEntry' do
      let(:core_model) { Coradoc::CoreModel::TocEntry.new(title: 'Section 1', level: 1) }

      it 'produces a Text element with title' do
        expect(transform).to be_a(Coradoc::Markdown::Text)
        expect(transform.content).to eq('Section 1')
      end
    end

    context 'with CommentLine' do
      let(:core_model) { Coradoc::CoreModel::CommentLine.new(text: 'note to self') }

      it 'produces a Markdown::Comment preserving text' do
        expect(transform).to be_a(Coradoc::Markdown::Comment)
        expect(transform.text).to eq('note to self')
      end
    end

    context 'with CommentBlock' do
      let(:core_model) { Coradoc::CoreModel::CommentBlock.new(content: 'hidden block') }

      it 'produces a Markdown::Comment preserving content' do
        expect(transform).to be_a(Coradoc::Markdown::Comment)
        expect(transform.text).to eq('hidden block')
      end
    end

    context 'with Block (paragraph containing inline elements)' do
      let(:core_model) do
        block = Coradoc::CoreModel::Block.new(
          element_type: 'paragraph',
          content: 'Hello bold and italic text'
        )
        block.children = [
          'Hello ',
          Coradoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'bold'),
          ' and ',
          Coradoc::CoreModel::InlineElement.new(format_type: 'italic', content: 'italic'),
          ' text'
        ]
        block
      end

      it 'transforms children with inline elements' do
        expect(transform).to be_a(Coradoc::Markdown::Paragraph)
        expect(transform.children).to be_an(Array)
        expect(transform.children.length).to eq(5)

        # Verify inline elements are preserved
        strong = transform.children.find { |c| c.is_a?(Coradoc::Markdown::Strong) }
        emphasis = transform.children.find { |c| c.is_a?(Coradoc::Markdown::Emphasis) }
        expect(strong).not_to be_nil
        expect(emphasis).not_to be_nil
        expect(strong.text).to eq('bold')
        expect(emphasis.text).to eq('italic')
      end
    end

    context 'with Block (paragraph containing link inline element)' do
      let(:core_model) do
        block = Coradoc::CoreModel::Block.new(
          element_type: 'paragraph',
          content: 'Visit example'
        )
        block.children = [
          'Visit ',
          Coradoc::CoreModel::InlineElement.new(
            format_type: 'link',
            content: 'example',
            target: 'https://example.com'
          )
        ]
        block
      end

      it 'transforms link inline elements within paragraph children' do
        expect(transform).to be_a(Coradoc::Markdown::Paragraph)
        link = transform.children.find { |c| c.is_a?(Coradoc::Markdown::Link) }
        expect(link).not_to be_nil
        expect(link.text).to eq('example')
        expect(link.url).to eq('https://example.com')
      end
    end
  end
end
