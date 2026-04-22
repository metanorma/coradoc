# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::DocumentBuilder do
  describe '.build' do
    it 'creates a document builder' do
      builder = described_class.build do
        title 'Test Document'
      end

      expect(builder).to be_a(described_class)
      expect(builder.document.title).to eq('Test Document')
    end
  end

  describe '#title' do
    it 'sets the document title' do
      builder = described_class.build do
        title 'My Document'
      end

      expect(builder.document.title).to eq('My Document')
    end
  end

  describe '#section' do
    it 'creates a section with title' do
      builder = described_class.build do
        section 'Introduction'
      end

      expect(builder.document.children).not_to be_empty
      section = builder.document.children.first
      expect(section.element_type).to eq('section')
      expect(section.title).to eq('Introduction')
    end

    it 'creates a section with content block' do
      builder = described_class.build do
        section 'Getting Started' do
          paragraph 'First paragraph'
          paragraph 'Second paragraph'
        end
      end

      section = builder.document.children.first
      expect(section.children.length).to eq(2)
    end

    it 'supports nested sections' do
      builder = described_class.build do
        section 'Chapter 1' do
          section 'Section 1.1', level: 2 do
            paragraph 'Content'
          end
        end
      end

      chapter = builder.document.children.first
      expect(chapter.title).to eq('Chapter 1')

      sub_section = chapter.children.first
      expect(sub_section.title).to eq('Section 1.1')
      expect(sub_section.level).to eq(2)
    end
  end

  describe '#paragraph' do
    it 'creates a paragraph' do
      builder = described_class.build do
        paragraph 'This is a paragraph.'
      end

      para = builder.document.children.first
      expect(para.element_type).to eq('paragraph')
      expect(para.content).to eq('This is a paragraph.')
    end
  end

  describe '#code' do
    it 'creates a code block' do
      builder = described_class.build do
        code "puts 'hello'", language: 'ruby'
      end

      code_block = builder.document.children.first
      expect(code_block.element_type).to eq('block')
      expect(code_block.content).to eq("puts 'hello'")
      expect(code_block.language).to eq('ruby')
    end

    it 'creates a code block without language' do
      builder = described_class.build do
        code 'some code'
      end

      code_block = builder.document.children.first
      expect(code_block.language).to be_nil
    end
  end

  describe '#blockquote' do
    it 'creates a blockquote' do
      builder = described_class.build do
        blockquote 'To be or not to be'
      end

      quote = builder.document.children.first
      expect(quote.delimiter_type).to eq('____')
      expect(quote.content).to eq('To be or not to be')
    end

    it 'creates a blockquote with attribution' do
      builder = described_class.build do
        blockquote 'To be or not to be', attribution: 'Shakespeare'
      end

      quote = builder.document.children.first
      expect(quote.metadata('attribution')).to eq('Shakespeare')
    end
  end

  describe '#list' do
    it 'creates an unordered list' do
      builder = described_class.build do
        list :unordered do
          item 'First'
          item 'Second'
          item 'Third'
        end
      end

      list = builder.document.children.first
      expect(list.marker_type).to eq('unordered')
      expect(list.items.length).to eq(3)
    end

    it 'creates an ordered list' do
      builder = described_class.build do
        list :ordered do
          item 'Step 1'
          item 'Step 2'
        end
      end

      list = builder.document.children.first
      expect(list.marker_type).to eq('ordered')
    end

    it 'supports list aliases' do
      builder1 = described_class.build { bulleted_list { item 'A' } }
      builder2 = described_class.build { numbered_list { item 'B' } }

      expect(builder1.document.children.first.marker_type).to eq('unordered')
      expect(builder2.document.children.first.marker_type).to eq('ordered')
    end
  end

  describe '#image' do
    it 'creates an image' do
      builder = described_class.build do
        image 'photo.jpg', alt: 'A photo'
      end

      img = builder.document.children.first
      expect(img).to be_a(Coradoc::CoreModel::Image)
      expect(img.src).to eq('photo.jpg')
      expect(img.alt).to eq('A photo')
    end
  end

  describe '#table' do
    it 'creates a table with headers and rows' do
      builder = described_class.build do
        table %w[Name Age], [
          %w[Alice 30],
          %w[Bob 25]
        ]
      end

      table = builder.document.children.first
      expect(table.rows.length).to eq(3) # 1 header + 2 data rows
    end
  end

  describe '#admonition' do
    it 'creates a note admonition' do
      builder = described_class.build do
        note 'This is important'
      end

      note_block = builder.document.children.first
      expect(note_block).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(note_block.annotation_type).to eq('note')
    end

    it 'creates a warning admonition' do
      builder = described_class.build do
        warning 'Be careful!'
      end

      warning_block = builder.document.children.first
      expect(warning_block.annotation_type).to eq('warning')
    end
  end

  describe '#to_core' do
    it 'returns the CoreModel document' do
      builder = described_class.build do
        title 'Test'
        paragraph 'Content'
      end

      core = builder.to_core
      expect(core).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(core.element_type).to eq('document')
    end
  end

  describe '#to_html' do
    it 'converts the document to HTML' do
      builder = described_class.build do
        title 'Test'
        paragraph 'Content'
      end

      html = builder.to_html
      expect(html).to include('<!DOCTYPE html>')
    end
  end

  describe 'Coradoc.build' do
    it 'provides a convenience method' do
      builder = Coradoc.build do
        title 'Convenience'
      end

      expect(builder).to be_a(described_class)
      expect(builder.document.title).to eq('Convenience')
    end
  end

  describe 'complex documents' do
    it 'builds a complex document' do
      builder = described_class.build do
        title 'API Documentation'

        section 'Introduction' do
          paragraph 'This is the API documentation.'
          note 'API v2 is now available.'
        end

        section 'Getting Started' do
          paragraph 'Follow these steps:'
          list :ordered do
            item 'Install the gem'
            item 'Configure your API key'
            item 'Make your first request'
          end
        end

        section 'Examples' do
          code 'client = Api::Client.new(key)', language: 'ruby'
        end
      end

      core = builder.to_core
      expect(core.title).to eq('API Documentation')
      expect(core.children.length).to eq(3)
    end
  end
end
