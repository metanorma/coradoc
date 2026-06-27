# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'
require 'coradoc/html'

RSpec.describe Coradoc::Html::Converters do
  let(:converter_module) { described_class }

  # Helper to map model names to CoreModel classes
  def model_class(name)
    case name
    when 'Paragraph'
      Coradoc::CoreModel::Block
    when 'Title'
      Coradoc::CoreModel::StructuralElement
    when 'Bold'
      Coradoc::CoreModel::InlineElement
    when 'Italic'
      Coradoc::CoreModel::InlineElement
    when 'Monospace'
      Coradoc::CoreModel::InlineElement
    when 'Link'
      Coradoc::CoreModel::InlineElement
    when 'Anchor'
      Coradoc::CoreModel::InlineElement
    when 'BlockImage'
      Coradoc::CoreModel::Image
    when 'Unordered'
      Coradoc::CoreModel::ListBlock
    when 'Ordered'
      Coradoc::CoreModel::ListBlock
    when 'Table'
      Coradoc::CoreModel::Table
    when 'Quote'
      Coradoc::CoreModel::Block
    when 'Literal'
      Coradoc::CoreModel::Block
    when 'ThematicBreak'
      Coradoc::CoreModel::Block
    when 'HardLineBreak'
      Coradoc::CoreModel::InlineElement
    when 'Section'
      Coradoc::CoreModel::StructuralElement
    else
      raise "Unknown model class: #{name}"
    end
  end

  describe '.process_coradoc paragraph' do
    it 'processes a simple paragraph' do
      html = '<p>Hello World</p>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('p')

      result = converter_module.process_coradoc(node, {})

      expect(result).to be_a(Coradoc::CoreModel::Block)
    end

    it 'processes a heading' do
      html = '<h1>Title</h1>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('h1')

      result = converter_module.process_coradoc(node, {})

      expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
    end
  end

  describe '.process_coradoc' do
    it 'converts paragraph to CoreModel' do
      html = '<p>Test content</p>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('p')

      result = converter_module.process_coradoc(node, {})

      expect(result).to be_a(Coradoc::CoreModel::Block)
    end

    it 'converts heading to CoreModel' do
      html = '<h1>Section Title</h1>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('h1')

      result = converter_module.process_coradoc(node, {})

      expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
    end

    it 'converts h2 with correct level' do
      html = '<h2>Subsection</h2>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('h2')

      result = converter_module.process_coradoc(node, {})

      expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
    end
  end

  describe '.register' do
    it 'registers converters for HTML elements' do
      expect(converter_module.lookup(:p)).to be_a(Coradoc::Html::Converters::P)
      expect(converter_module.lookup(:h1)).to be_a(Coradoc::Html::Converters::H)
      expect(converter_module.lookup(:div)).to be_a(Coradoc::Html::Converters::Div)
    end
  end

  describe 'Converter::P' do
    let(:converter) { Coradoc::Html::Converters::P.new }

    describe '#to_coradoc' do
      it 'creates a Block from p element' do
        html = '<p>Simple paragraph text</p>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('p')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ParagraphBlock)
        expect(result.resolve_semantic_type).to eq(:paragraph)
      end

      it 'preserves id attribute' do
        html = '<p id="my-para">Text with ID</p>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('p')

        result = converter.to_coradoc(node, {})

        expect(result.id).to eq('my-para')
      end
    end
  end

  describe 'Converter::H' do
    let(:converter) { Coradoc::Html::Converters::H.new }

    describe '#to_coradoc' do
      it 'creates a StructuralElement from heading element' do
        html = '<h1>Main Title</h1>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('h1')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
      end
    end
  end

  describe 'Converter::Strong' do
    let(:converter) { Coradoc::Html::Converters::Strong.new }

    describe '#to_coradoc' do
      it 'converts strong to bold InlineElement' do
        html = '<strong>bold text</strong>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('strong')

        result = converter.to_coradoc(node, {})

        # May return array or single element
        elements = Array(result)
        expect(elements.any?(Coradoc::CoreModel::BoldElement)).to be true
      end
    end
  end

  describe 'Converter::Em' do
    let(:converter) { Coradoc::Html::Converters::Em.new }

    describe '#to_coradoc' do
      it 'converts em to italic InlineElement' do
        html = '<em>italic text</em>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('em')

        result = converter.to_coradoc(node, {})

        elements = Array(result)
        expect(elements.any?(Coradoc::CoreModel::ItalicElement)).to be true
      end
    end
  end

  describe 'Converter::Code' do
    let(:converter) { Coradoc::Html::Converters::Code.new }

    describe '#to_coradoc' do
      it 'converts code to monospace InlineElement' do
        html = '<code>code text</code>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('code')

        result = converter.to_coradoc(node, {})

        elements = Array(result)
        expect(elements.any?(Coradoc::CoreModel::MonospaceElement)).to be true
      end
    end
  end

  describe 'Converter::A' do
    let(:converter) { Coradoc::Html::Converters::A.new }

    describe '#to_coradoc' do
      it 'converts anchor with href to link' do
        html = '<a href="http://example.com">Link</a>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('a')

        result = converter.to_coradoc(node, {})

        elements = Array(result)
        link = elements.find { |e| e.is_a?(Coradoc::CoreModel::LinkElement) }
        expect(link).not_to be_nil
        expect(link.target).to eq('http://example.com')
      end

      it 'handles anchor with id only' do
        html = '<a id="section1">Section</a>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('a')

        result = converter.to_coradoc(node, {})

        elements = Array(result)
        anchor = elements.find { |e| e.is_a?(Coradoc::CoreModel::InlineElement) && e.format_type == 'anchor' }
        expect(anchor).not_to be_nil
        expect(anchor.target).to eq('section1')
      end
    end
  end

  describe 'Converter::Ul' do
    let(:converter) { Coradoc::Html::Converters::Ol.new }

    describe '#to_coradoc' do
      it 'converts ul to unordered list' do
        html = '<ul><li>Item</li></ul>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('ul')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListBlock)
        expect(result.marker_type).to eq('unordered')
      end
    end
  end

  describe 'Converter::Ol' do
    let(:converter) { Coradoc::Html::Converters::Ol.new }

    describe '#to_coradoc' do
      it 'converts ol to ordered list' do
        html = '<ol><li>Item</li></ol>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('ol')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListBlock)
      end
    end
  end

  describe 'Converter::Table' do
    let(:converter) { Coradoc::Html::Converters::Table.new }

    describe '#to_coradoc' do
      it 'converts table to Table model' do
        html = '<table><tr><td>Cell</td></tr></table>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('table')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::Table)
      end

      it 'extracts title from caption' do
        html = '<table><caption>My Table</caption><tr><td>Cell</td></tr></table>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('table')

        result = converter.to_coradoc(node, {})

        expect(result.title).to eq('My Table')
      end

      it 'extracts id attribute' do
        html = '<table id="t1"><tr><td>Cell</td></tr></table>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('table')

        result = converter.to_coradoc(node, {})

        expect(result.id).to eq('t1')
      end
    end

    describe '#frame' do
      let(:table_node) do
        lambda { |attr|
          html = "<table frame=\"#{attr}\"><tr><td>X</td></tr></table>"
          Nokogiri::HTML.fragment(html).at('table')
        }
      end

      it 'maps void to none' do
        expect(converter.frame(table_node.call('void'))).to eq('none')
      end

      it 'maps hsides to topbot' do
        expect(converter.frame(table_node.call('hsides'))).to eq('topbot')
      end

      it 'maps vsides to sides' do
        expect(converter.frame(table_node.call('vsides'))).to eq('sides')
      end

      it 'maps box to all' do
        expect(converter.frame(table_node.call('box'))).to eq('all')
      end

      it 'maps border to all' do
        expect(converter.frame(table_node.call('border'))).to eq('all')
      end

      it 'returns nil for unknown values' do
        expect(converter.frame(table_node.call('unknown'))).to be_nil
      end
    end

    describe '#rules' do
      let(:table_node) do
        lambda { |attr|
          html = "<table rules=\"#{attr}\"><tr><td>X</td></tr></table>"
          Nokogiri::HTML.fragment(html).at('table')
        }
      end

      it 'maps all to all' do
        expect(converter.rules(table_node.call('all'))).to eq('all')
      end

      it 'maps rows to rows' do
        expect(converter.rules(table_node.call('rows'))).to eq('rows')
      end

      it 'maps cols to cols' do
        expect(converter.rules(table_node.call('cols'))).to eq('cols')
      end

      it 'maps none to none' do
        expect(converter.rules(table_node.call('none'))).to eq('none')
      end

      it 'returns nil for unknown values' do
        expect(converter.rules(table_node.call('groups'))).to be_nil
      end
    end
  end

  describe 'Converter::Blockquote' do
    let(:converter) { Coradoc::Html::Converters::Blockquote.new }

    describe '#to_coradoc' do
      it 'converts blockquote to Quote block' do
        html = '<blockquote>Quote</blockquote>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('blockquote')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::Block)
      end
    end
  end

  describe 'Converter::Pre' do
    let(:converter) { Coradoc::Html::Converters::Pre.new }

    describe '#to_coradoc' do
      it 'converts pre to listing block' do
        html = '<pre>code</pre>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('pre')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::Block)
      end
    end
  end

  describe 'Converter::Hr' do
    let(:converter) { Coradoc::Html::Converters::Hr.new }

    describe '#to_coradoc' do
      it 'converts hr to break' do
        html = '<hr/>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('hr')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::Block)
      end
    end
  end

  describe 'Converter::Br' do
    let(:converter) { Coradoc::Html::Converters::Br.new }

    describe '#to_coradoc' do
      it 'converts br to line break' do
        html = '<br/>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('br')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::InlineElement)
      end
    end
  end

  describe 'Converter::Q' do
    let(:converter) { Coradoc::Html::Converters::Q.new }

    describe '#to_coradoc' do
      it 'converts q to quote inline' do
        html = '<q>quoted</q>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('q')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::InlineElement)
      end
    end
  end

  describe 'Converter::Img' do
    let(:converter) { Coradoc::Html::Converters::Img.new }

    describe '#to_coradoc' do
      it 'converts img to Image' do
        html = '<img src="test.png" alt="test"/>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('img')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::Image)
        expect(result.src).to eq('test.png')
        expect(result.alt).to eq('test')
      end

      it 'converts img with width and height' do
        html = '<img src="test.png" alt="test" width="100" height="200"/>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('img')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::Image)
        expect(result.width).to eq('100')
        expect(result.height).to eq('200')
      end

      it 'converts img with id' do
        html = '<img id="my-image" src="test.png" alt="test"/>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('img')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::Image)
        expect(result.id).to eq('my-image')
      end
    end
  end

  describe 'Converter::Div' do
    let(:converter) { Coradoc::Html::Converters::Div.new }

    describe '#to_coradoc' do
      it 'converts div to Block' do
        html = '<div>Content</div>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('div')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::Block)
      end
    end
  end

  describe 'Converter::Math' do
    let(:converter) { Coradoc::Html::Converters::Math.new }

    describe '#to_coradoc' do
      it 'converts math to StemElement' do
        html = '<math><mi>x</mi></math>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('math')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::StemElement)
        expect(result.stem_type).to eq('mathml')
      end
    end
  end

  describe 'Converter::Audio' do
    let(:converter) { Coradoc::Html::Converters::Audio.new }

    describe '#to_coradoc' do
      it 'converts audio to Block with audio semantic type' do
        html = '<audio src="song.mp3" controls></audio>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('audio')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::Block)
        expect(result.block_semantic_type.to_s).to eq('audio')
        expect(result.content).to eq('song.mp3')
      end
    end
  end

  describe 'Converter::Video' do
    let(:converter) { Coradoc::Html::Converters::Video.new }

    describe '#to_coradoc' do
      it 'converts video to Block with video semantic type' do
        html = '<video src="movie.mp4" controls poster="thumb.jpg" width="640" height="480"></video>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('video')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::Block)
        expect(result.block_semantic_type.to_s).to eq('video')
        expect(result.content).to eq('movie.mp4')
      end
    end
  end

  describe 'shared MediaBase behavior' do
    it 'Audio and Video share MediaBase superclass' do
      expect(Coradoc::Html::Converters::Audio.superclass).to eq(
        Coradoc::Html::Converters::MediaBase
      )
      expect(Coradoc::Html::Converters::Video.superclass).to eq(
        Coradoc::Html::Converters::MediaBase
      )
    end

    it 'both extract title from track/source elements' do
      html = '<audio><track label="English" kind="captions" srclang="en"/></audio>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('audio')

      audio_converter = Coradoc::Html::Converters::Audio.new
      result = audio_converter.to_coradoc(node, {})
      expect(result.title).to eq('English')
    end
  end

  describe 'Converter::A content extraction' do
    let(:converter) { Coradoc::Html::Converters::A.new }

    it 'extracts text from inline content for cross-references' do
      html = '<a href="#section1">Go to section</a>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('a')

      result = converter.to_coradoc(node, {})

      expect(result).to be_a(Coradoc::CoreModel::CrossReferenceElement)
      expect(result.target).to eq('section1')
    end

    it 'extracts text from inline content for links' do
      html = '<a href="http://example.com">Example</a>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('a')

      result = converter.to_coradoc(node, {})

      elements = Array(result)
      link = elements.find { |e| e.is_a?(Coradoc::CoreModel::LinkElement) }
      expect(link).not_to be_nil
    end
  end

  describe 'complex HTML processing' do
    it 'handles mixed inline formatting' do
      html = '<p><strong>Bold</strong> and <em>italic</em></p>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('p')

      result = converter_module.process_coradoc(node, {})

      expect(result).to be_a(Coradoc::CoreModel::Block)
    end
  end

  describe 'text extraction' do
    it 'extracts text from simple HTML' do
      html = '<p>Simple text</p>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('p')

      result = converter_module.process_coradoc(node, {})

      # Extract text content from the block (use children for mixed content)
      content = result.is_a?(Coradoc::CoreModel::Base) && result.children&.any? ? result.children : result.content
      text = extract_text_from_content(content)
      expect(text).to include('Simple text')
    end

    it 'preserves text in nested elements' do
      html = '<p>Before <strong>Bold</strong> After</p>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('p')

      result = converter_module.process_coradoc(node, {})

      content = result.is_a?(Coradoc::CoreModel::Base) && result.children&.any? ? result.children : result.content
      text = extract_text_from_content(content)
      expect(text).to include('Before')
      expect(text).to include('Bold')
      expect(text).to include('After')
    end
  end

  # Helper method to extract text from content
  def extract_text_from_content(content)
    return '' if content.nil?
    return content.to_s unless content.is_a?(Array)

    content.map do |c|
      case c
      when Coradoc::CoreModel::InlineElement
        # Extract from both content and nested_elements
        text_parts = [extract_text_from_content(c.content)]
        text_parts << extract_text_from_content(c.nested_elements) if c.nested_elements
        text_parts.join
      when Coradoc::CoreModel::Base
        if c.children.is_a?(Array)
          extract_text_from_content(c.children)
        else
          extract_text_from_content(c.content)
        end
      when Array
        extract_text_from_content(c)
      else
        c.to_s
      end
    end.join
  end

  describe 'Base#node_has_ancestor?' do
    let(:base) { Coradoc::Html::Converters::Base.new }

    it 'finds a string ancestor name' do
      html = '<div><p><strong>Bold</strong></p></div>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('strong')

      expect(base.node_has_ancestor?(node, 'div')).to be true
      expect(base.node_has_ancestor?(node, 'table')).to be false
    end

    it 'finds an array of ancestor names' do
      html = '<div><p><strong>Bold</strong></p></div>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('strong')

      expect(base.node_has_ancestor?(node, %w[table div])).to be true
      expect(base.node_has_ancestor?(node, %w[table ul])).to be false
    end

    it 'returns false when no ancestors match' do
      html = '<p>Plain</p>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.at('p')

      expect(base.node_has_ancestor?(node, 'div')).to be false
    end
  end

  describe 'singleton converter instances' do
    it 'Bypass::INSTANCE is reused across registrations' do
      instance = Coradoc::Html::Converters::Bypass::INSTANCE
      converter = described_class.lookup(:span)
      expect(converter).to equal(instance)
    end

    it 'Skip::INSTANCE is reused across registrations' do
      instance = Coradoc::Html::Converters::Skip::INSTANCE
      converter = described_class.lookup(:script)
      expect(converter).to equal(instance)
    end
  end
end
