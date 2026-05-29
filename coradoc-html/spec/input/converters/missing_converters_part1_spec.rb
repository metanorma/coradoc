# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe Coradoc::Input::Html::Converters do
  describe 'Converter::Aside' do
    let(:converter) { Coradoc::Input::Html::Converters::Aside.new }

    describe '#to_coradoc' do
      it 'creates a SidebarBlock from an aside element' do
        html = '<aside>Some sidebar content</aside>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('aside')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::SidebarBlock)
      end

      it 'passes child content through to the SidebarBlock' do
        html = '<aside><p>Paragraph in sidebar</p></aside>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('aside')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::SidebarBlock)
        expect(result.children).not_to be_empty
      end

      it 'handles an empty aside element' do
        html = '<aside></aside>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('aside')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::SidebarBlock)
        expect(result.children).to be_empty
      end

      it 'preserves multiple child elements' do
        html = '<aside><p>First</p><p>Second</p><p>Third</p></aside>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('aside')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::SidebarBlock)
        expect(result.children.length).to be >= 3
      end
    end
  end

  describe 'Converter::Dl' do
    let(:converter) { Coradoc::Input::Html::Converters::Dl.new }

    describe '#to_coradoc' do
      it 'creates a ListBlock with definition marker_type from a dl element' do
        html = '<dl><dt>Term</dt><dd>Definition</dd></dl>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('dl')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListBlock)
        expect(result.marker_type).to eq('definition')
      end

      it 'creates ListItem entries for each term-definition pair' do
        html = '<dl><dt>Apple</dt><dd>A fruit</dd><dt>Banana</dt><dd>Another fruit</dd></dl>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('dl')

        result = converter.to_coradoc(node, {})

        expect(result.items.length).to eq(2)
        expect(result.items[0]).to be_a(Coradoc::CoreModel::ListItem)
        expect(result.items[1]).to be_a(Coradoc::CoreModel::ListItem)
      end

      it 'extracts term text into ListItem content' do
        html = '<dl><dt>HTML</dt><dd>HyperText Markup Language</dd></dl>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('dl')

        result = converter.to_coradoc(node, {})

        expect(result.items[0].content).to eq('HTML')
      end

      it 'places definition content in ListItem children' do
        html = '<dl><dt>Term</dt><dd>Definition text</dd></dl>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('dl')

        result = converter.to_coradoc(node, {})

        expect(result.items[0].children).not_to be_empty
      end

      it 'handles multiple dd elements for a single dt' do
        html = '<dl><dt>Term</dt><dd>First definition</dd><dd>Second definition</dd></dl>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('dl')

        result = converter.to_coradoc(node, {})

        # The process_dl loop appends the current group after each dd child,
        # so multiple consecutive dd elements produce separate items
        expect(result.items.length).to eq(2)
        expect(result.items[0]).to be_a(Coradoc::CoreModel::ListItem)
        expect(result.items[1]).to be_a(Coradoc::CoreModel::ListItem)
      end

      it 'handles an empty dl element' do
        html = '<dl></dl>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('dl')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListBlock)
        expect(result.marker_type).to eq('definition')
        expect(result.items).to be_empty
      end

      it 'handles dt/dd elements wrapped in div containers' do
        html = '<dl><div><dt>Term</dt><dd>Definition</dd></div></dl>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('dl')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListBlock)
        expect(result.marker_type).to eq('definition')
        expect(result.items.length).to eq(1)
      end
    end
  end

  describe 'Converter::Figure' do
    let(:converter) { Coradoc::Input::Html::Converters::Figure.new }

    describe '#to_coradoc' do
      it 'creates an ExampleBlock from a figure element' do
        html = '<figure><img src="photo.png" alt="A photo"/></figure>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('figure')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ExampleBlock)
      end

      it 'extracts title from figcaption' do
        html = '<figure><figcaption>My Figure</figcaption><img src="photo.png" alt="photo"/></figure>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('figure')

        result = converter.to_coradoc(node, {})

        expect(result.title).to include('My Figure')
      end

      it 'sets id attribute from the figure element' do
        html = '<figure id="fig-1"><img src="photo.png" alt="photo"/></figure>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('figure')

        result = converter.to_coradoc(node, {})

        expect(result.id).to eq('fig-1')
      end

      it 'handles a figure without figcaption' do
        html = '<figure><img src="photo.png" alt="photo"/></figure>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('figure')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ExampleBlock)
        expect(result.title).to eq('')
      end

      it 'handles a figure without id' do
        html = '<figure><img src="photo.png" alt="photo"/></figure>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('figure')

        result = converter.to_coradoc(node, {})

        expect(result.id).to be_nil
      end

      it 'passes child content through to the ExampleBlock' do
        html = '<figure><img src="photo.png" alt="photo"/><figcaption>Caption</figcaption></figure>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('figure')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ExampleBlock)
        expect(result.children).not_to be_empty
      end
    end
  end

  describe 'Converter::Head' do
    let(:converter) { Coradoc::Input::Html::Converters::Head.new }

    # Helper: Nokogiri::HTML.fragment drops <head> since it's a structural
    # element, so we parse a full document and extract the <head> node.
    def head_node_from(html)
      doc = Nokogiri::HTML.parse(html)
      doc.at('head')
    end

    describe '#to_coradoc' do
      it 'creates a DocumentElement from a head element' do
        node = head_node_from('<html><head><title>My Document</title></head></html>')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::DocumentElement)
      end

      it 'extracts title from the title element' do
        node = head_node_from('<html><head><title>My Document</title></head></html>')

        result = converter.to_coradoc(node, {})

        expect(result.title).to eq('My Document')
      end

      it 'sets level to 0' do
        node = head_node_from('<html><head><title>My Document</title></head></html>')

        result = converter.to_coradoc(node, {})

        expect(result.level).to eq(0)
      end

      it 'returns placeholder title when title element is missing' do
        node = head_node_from('<html><head></head></html>')

        result = converter.to_coradoc(node, {})

        expect(result.title).to eq('(???)')
      end

      it 'handles an empty title element' do
        node = head_node_from('<html><head><title></title></head></html>')

        result = converter.to_coradoc(node, {})

        expect(result.title).to eq('')
      end

      it 'extracts multi-word title text' do
        node = head_node_from('<html><head><title>A Very Long Document Title Here</title></head></html>')

        result = converter.to_coradoc(node, {})

        expect(result.title).to eq('A Very Long Document Title Here')
      end
    end
  end
end
