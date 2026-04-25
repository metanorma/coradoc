# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cross-Format Integration', type: :integration do
  describe 'AsciiDoc → CoreModel → HTML flow' do
    let(:adoc_content) do
      <<~ADOC
        = Document Title

        == Section 1

        This is a paragraph with *bold* and _italic_ text.

        === Subsection

        * Item 1
        * Item 2
        * Item 3

        [source,ruby]
        ----
        def hello
          puts "world"
        end
        ----
      ADOC
    end

    it 'transforms AsciiDoc to CoreModel' do
      skip 'AsciiDoc parser required' unless defined?(Coradoc::AsciiDoc::Parser::Base)

      ast = Coradoc::AsciiDoc::Parser::Base.parse(adoc_content)
      adoc_doc = Coradoc::AsciiDoc::Transformer.transform(ast)
      core_doc = Coradoc::AsciiDoc::Transform::ToCoreModel.transform(adoc_doc)

      expect(core_doc).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(core_doc.element_type).to eq('document')
      expect(core_doc.title).to eq('Document Title')
    end

    it 'transforms CoreModel to HTML' do
      skip 'AsciiDoc parser required' unless defined?(Coradoc::AsciiDoc::Parser::Base)

      ast = Coradoc::AsciiDoc::Parser::Base.parse(adoc_content)
      adoc_doc = Coradoc::AsciiDoc::Transformer.transform(ast)
      core_doc = Coradoc::AsciiDoc::Transform::ToCoreModel.transform(adoc_doc)

      html = Coradoc::Html.serialize_static(core_doc)

      expect(html).to be_a(String)
      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('Document Title')
    end
  end

  describe 'Markdown → CoreModel → HTML flow' do
    let(:md_content) do
      <<~MD
        # Document Title

        ## Section 1

        This is a paragraph with **bold** and *italic* text.

        - Item 1
        - Item 2
        - Item 3

        ```ruby
        def hello
          puts "world"
        end
        ```
      MD
    end

    it 'transforms Markdown to CoreModel' do
      md_doc = Coradoc::Markdown.parse(md_content)
      core_doc = Coradoc::Markdown.to_core_model(md_doc)

      expect(core_doc).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(core_doc.element_type).to eq('document')
    end

    it 'transforms CoreModel to HTML' do
      md_doc = Coradoc::Markdown.parse(md_content)
      core_doc = Coradoc::Markdown.to_core_model(md_doc)

      html = Coradoc::Html.serialize_static(core_doc)

      expect(html).to be_a(String)
      expect(html).to include('<!DOCTYPE html>')
    end
  end

  describe 'CoreModel round-trip' do
    it 'preserves document structure through CoreModel' do
      # Create a CoreModel document directly
      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test Document',
        children: [
          Coradoc::CoreModel::StructuralElement.new(
            element_type: 'section',
            level: 1,
            title: 'Section 1',
            children: [
              Coradoc::CoreModel::Block.new(
                element_type: 'paragraph',
                content: 'Paragraph content'
              )
            ]
          )
        ]
      )

      # Convert to Markdown
      md_doc = Coradoc::Markdown.from_core_model(core_doc)
      expect(md_doc).to be_a(Coradoc::Markdown::Document)

      # Convert back to CoreModel
      core_doc2 = Coradoc::Markdown.to_core_model(md_doc)
      expect(core_doc2).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(core_doc2.element_type).to eq('document')
      # NOTE: Title extraction picks first heading in Markdown
      expect(core_doc2.children.first).to be_a(Coradoc::CoreModel::StructuralElement)
    end
  end

  describe 'Coradoc convenience API' do
    it 'provides Coradoc.to_core for model conversion' do
      skip 'AsciiDoc parser required' unless defined?(Coradoc::AsciiDoc::Parser::Base)

      adoc = "= Title\n\nParagraph"
      ast = Coradoc::AsciiDoc::Parser::Base.parse(adoc)
      adoc_doc = Coradoc::AsciiDoc::Transformer.transform(ast)

      core_doc = Coradoc.to_core(adoc_doc)

      expect(core_doc).to be_a(Coradoc::CoreModel::StructuralElement)
    end
  end

  describe 'AsciiDoc → CoreModel → Markdown flow' do
    let(:adoc_content) do
      <<~ADOC
        = Document Title

        == Section 1

        This is a paragraph.

        * Item 1
        * Item 2
      ADOC
    end

    it 'transforms AsciiDoc to CoreModel to Markdown' do
      skip 'AsciiDoc parser required' unless defined?(Coradoc::AsciiDoc::Parser::Base)

      # Parse AsciiDoc
      ast = Coradoc::AsciiDoc::Parser::Base.parse(adoc_content)
      adoc_doc = Coradoc::AsciiDoc::Transformer.transform(ast)

      # Transform to CoreModel
      core_doc = Coradoc::AsciiDoc::Transform::ToCoreModel.transform(adoc_doc)
      expect(core_doc).to be_a(Coradoc::CoreModel::StructuralElement)

      # Transform to Markdown
      md_doc = Coradoc::Markdown.from_core_model(core_doc)
      expect(md_doc).to be_a(Coradoc::Markdown::Document)
      expect(md_doc.blocks.length).to be > 0
    end
  end

  describe 'Format registry' do
    it 'registers all format gems' do
      expect(Coradoc.registered_formats).to include(:asciidoc)
      expect(Coradoc.registered_formats).to include(:html)
      expect(Coradoc.registered_formats).to include(:markdown)
    end

    it 'registers docx gem when available' do
      skip 'DOCX gem not loaded' unless defined?(Coradoc::Docx)

      expect(Coradoc.registered_formats).to include(:docx)
    end

    it 'provides format module access' do
      expect(Coradoc.get_format(:asciidoc)).to eq(Coradoc::AsciiDoc)
      expect(Coradoc.get_format(:html)).to eq(Coradoc::Html)
      expect(Coradoc.get_format(:markdown)).to eq(Coradoc::Markdown)
    end
  end

  describe 'CoreModel type transformations' do
    it 'transforms Block with paragraph type correctly' do
      block = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: 'Test content'
      )

      md = Coradoc::Markdown.from_core_model(block)
      expect(md).to be_a(Coradoc::Markdown::Paragraph)
    end

    it 'transforms Block with code delimiter correctly' do
      block = Coradoc::CoreModel::Block.new(
        element_type: 'block',
        delimiter_type: '```',
        content: 'code here',
        language: 'ruby'
      )

      md = Coradoc::Markdown.from_core_model(block)
      expect(md).to be_a(Coradoc::Markdown::CodeBlock)
      expect(md.language).to eq('ruby')
    end

    it 'transforms ListBlock correctly' do
      list = Coradoc::CoreModel::ListBlock.new(
        marker_type: 'unordered',
        items: [
          Coradoc::CoreModel::ListItem.new(content: 'Item 1', marker: '*'),
          Coradoc::CoreModel::ListItem.new(content: 'Item 2', marker: '*')
        ]
      )

      md = Coradoc::Markdown.from_core_model(list)
      expect(md).to be_a(Coradoc::Markdown::List)
      expect(md.ordered).to be false
      expect(md.items.length).to eq(2)
    end

    it 'transforms InlineElement with bold type correctly' do
      inline = Coradoc::CoreModel::InlineElement.new(
        format_type: 'bold',
        content: 'bold text'
      )

      md = Coradoc::Markdown.from_core_model(inline)
      expect(md).to be_a(Coradoc::Markdown::Strong)
    end

    it 'transforms InlineElement with link type correctly' do
      inline = Coradoc::CoreModel::InlineElement.new(
        format_type: 'link',
        target: 'https://example.com',
        content: 'Example'
      )

      md = Coradoc::Markdown.from_core_model(inline)
      expect(md).to be_a(Coradoc::Markdown::Link)
      expect(md.url).to eq('https://example.com')
    end

    it 'transforms Image correctly' do
      image = Coradoc::CoreModel::Image.new(
        src: 'image.png',
        alt: 'Alt text'
      )

      md = Coradoc::Markdown.from_core_model(image)
      expect(md).to be_a(Coradoc::Markdown::Image)
      expect(md.src).to eq('image.png')
      expect(md.alt).to eq('Alt text')
    end
  end

  describe 'HTML output from CoreModel' do
    it 'renders paragraphs correctly' do
      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [
          Coradoc::CoreModel::Block.new(
            element_type: 'paragraph',
            content: 'This is a paragraph.'
          )
        ]
      )

      html = Coradoc::Html.serialize_static(core_doc)

      expect(html).to include('<p>')
      expect(html).to include('This is a paragraph.')
    end

    it 'renders sections with headings' do
      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [
          Coradoc::CoreModel::StructuralElement.new(
            element_type: 'section',
            level: 1,
            title: 'Main Section',
            children: []
          )
        ]
      )

      html = Coradoc::Html.serialize_static(core_doc)

      # AsciiDoc convention: level 1 section -> h2 (level 0 is document title)
      expect(html).to include('<h2')
      expect(html).to include('Main Section')
    end

    it 'renders lists correctly' do
      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [
          Coradoc::CoreModel::ListBlock.new(
            marker_type: 'unordered',
            items: [
              Coradoc::CoreModel::ListItem.new(content: 'Item 1', marker: '*'),
              Coradoc::CoreModel::ListItem.new(content: 'Item 2', marker: '*')
            ]
          )
        ]
      )

      html = Coradoc::Html.serialize_static(core_doc)

      expect(html).to include('<ul')
      expect(html).to include('<li')
      expect(html).to include('Item 1')
    end

    it 'renders code blocks with language' do
      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [
          Coradoc::CoreModel::Block.new(
            element_type: 'block',
            delimiter_type: '----', # Canonical source block delimiter
            content: "puts 'hello'",
            language: 'ruby'
          )
        ]
      )

      html = Coradoc::Html.serialize_static(core_doc)

      expect(html).to include('<pre')
      expect(html).to include('ruby')
    end
  end

  describe 'HTML → CoreModel → AsciiDoc flow' do
    let(:html_content) do
      <<~HTML
        <html>
          <body>
            <h1>Document Title</h1>
            <p>This is a paragraph with <strong>bold</strong> text.</p>
            <ul>
              <li>Item 1</li>
              <li>Item 2</li>
            </ul>
          </body>
        </html>
      HTML
    end

    it 'transforms HTML to CoreModel' do
      # Parse HTML to AsciiDoc model
      adoc_models = Coradoc::Input::Html.to_coradoc(html_content, {})

      expect(adoc_models).not_to be_nil
      expect(adoc_models).to be_an(Array)

      # Transform to CoreModel using AsciiDoc transformer
      # HTML input returns AsciiDoc models, so use AsciiDoc::Transform::ToCoreModel
      core_docs = adoc_models.map do |model|
        Coradoc::AsciiDoc::Transform::ToCoreModel.transform(model)
      end

      expect(core_docs).not_to be_empty
      expect(core_docs.first).to be_a(Coradoc::CoreModel::StructuralElement)
    end

    it 'transforms HTML → CoreModel → AsciiDoc' do
      html_input = <<~HTML
        <!DOCTYPE html>
        <html>
          <head><title>Test Document</title></head>
          <body>
            <h1>Main Heading</h1>
            <p>This is a paragraph.</p>
            <ul>
              <li>First item</li>
              <li>Second item</li>
            </ul>
          </body>
        </html>
      HTML

      # Step 1: Parse HTML to AsciiDoc model
      html_models = Coradoc::Input::Html.to_coradoc(html_input, {})
      expect(html_models).not_to be_nil
      expect(html_models).to be_an(Array)

      # Step 2: Transform to CoreModel (wrapping in document structure)
      # Create a document wrapper for the models
      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test Document',
        children: html_models.map do |model|
          Coradoc::AsciiDoc::Transform::ToCoreModel.transform(model)
        end.compact
      )
      expect(core_doc).to be_a(Coradoc::CoreModel::StructuralElement)

      # Step 3: Transform CoreModel to AsciiDoc model
      adoc_model = Coradoc::AsciiDoc::Transform::FromCoreModel.transform(core_doc)
      expect(adoc_model).not_to be_nil

      # Step 4: Serialize to AsciiDoc text
      adoc_text = adoc_model.to_adoc
      expect(adoc_text).to be_a(String)
      expect(adoc_text).to include('Main Heading')
    end
  end

  describe 'Full round-trip tests' do
    it 'round-trips CoreModel through HTML serialization' do
      # Create a CoreModel document
      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test Document',
        children: [
          Coradoc::CoreModel::StructuralElement.new(
            element_type: 'section',
            level: 1,
            title: 'Section 1',
            children: [
              Coradoc::CoreModel::Block.new(
                element_type: 'paragraph',
                content: 'Paragraph content'
              )
            ]
          )
        ]
      )

      # Convert to HTML
      html = Coradoc::Html.serialize_static(core_doc)

      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('Section 1')
      expect(html).to include('Paragraph content')
    end

    it 'round-trips CoreModel through Markdown' do
      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test Document',
        children: [
          Coradoc::CoreModel::Block.new(
            element_type: 'paragraph',
            content: 'Test paragraph'
          )
        ]
      )

      # Convert to Markdown
      md_doc = Coradoc::Markdown.from_core_model(core_doc)
      expect(md_doc).to be_a(Coradoc::Markdown::Document)

      # Convert back to CoreModel
      core_doc2 = Coradoc::Markdown.to_core_model(md_doc)
      expect(core_doc2).to be_a(Coradoc::CoreModel::StructuralElement)
    end
  end

  describe 'Cross-format model-driven conversions (no cross-format methods)' do
    describe 'Markdown Math → CoreModel → AsciiDoc' do
      it 'transforms inline math to CoreModel InlineElement with stem format' do
        math = Coradoc::Markdown::Math.inline('E = mc^2')
        core = Coradoc::Markdown.to_core_model(math)

        expect(core).to be_a(Coradoc::CoreModel::InlineElement)
        expect(core.format_type).to eq('stem')
        expect(core.content).to eq('E = mc^2')
      end

      it 'transforms block math to CoreModel Block with latexmath language' do
        math = Coradoc::Markdown::Math.block('\lambda_\alpha > 5')
        core = Coradoc::Markdown.to_core_model(math)

        expect(core).to be_a(Coradoc::CoreModel::Block)
        expect(core.delimiter_type).to eq('++++')
        expect(core.language).to eq('latexmath')
        expect(core.content).to eq('\lambda_\alpha > 5')
      end

      it 'round-trips inline math through CoreModel to AsciiDoc' do
        math = Coradoc::Markdown::Math.inline('E = mc^2')
        core = Coradoc::Markdown.to_core_model(math)
        adoc_inline = Coradoc::AsciiDoc::Transform::FromCoreModel.transform(core)

        expect(adoc_inline).to be_a(Coradoc::AsciiDoc::Model::Inline::Stem)
        expect(adoc_inline.type).to eq('latexmath')
        expect(adoc_inline.content).to eq('E = mc^2')

        # Verify AsciiDoc serialization
        adoc_text = adoc_inline.to_adoc
        expect(adoc_text).to eq('latexmath:[E = mc^2]')
      end

      it 'round-trips inline math through CoreModel back to Markdown' do
        math = Coradoc::Markdown::Math.inline('x^2 + y^2 = z^2')
        core = Coradoc::Markdown.to_core_model(math)
        md_math = Coradoc::Markdown.from_core_model(core)

        expect(md_math).to be_a(Coradoc::Markdown::Math)
        expect(md_math.content).to eq('x^2 + y^2 = z^2')
        expect(md_math.inline?).to be true
      end
    end

    describe 'Markdown Extension → CoreModel → AsciiDoc' do
      it 'transforms TOC extension to CoreModel::Toc' do
        toc = Coradoc::Markdown::Extension.toc
        core = Coradoc::Markdown.to_core_model(toc)

        expect(core).to be_a(Coradoc::CoreModel::Toc)
      end

      it 'transforms comment extension to CoreModel comment Block' do
        comment = Coradoc::Markdown::Extension.comment('This is a comment')
        core = Coradoc::Markdown.to_core_model(comment)

        expect(core).to be_a(Coradoc::CoreModel::Block)
        expect(core.element_type).to eq('comment')
        expect(core.content).to eq('This is a comment')
      end

      it 'transforms nomarkdown extension to CoreModel passthrough Block' do
        nomarkdown = Coradoc::Markdown::Extension.nomarkdown('<div>raw html</div>')
        core = Coradoc::Markdown.to_core_model(nomarkdown)

        expect(core).to be_a(Coradoc::CoreModel::Block)
        expect(core.delimiter_type).to eq('++++')
        expect(core.content).to eq('<div>raw html</div>')
      end

      it 'round-trips comment through CoreModel to AsciiDoc' do
        comment = Coradoc::Markdown::Extension.comment('Review note')
        core = Coradoc::Markdown.to_core_model(comment)
        adoc_model = Coradoc::AsciiDoc::Transform::FromCoreModel.transform(core)

        expect(adoc_model).to be_a(Coradoc::AsciiDoc::Model::CommentBlock)
        expect(adoc_model.text).to eq('Review note')

        adoc_text = adoc_model.to_adoc
        expect(adoc_text).to include('Review note')
        expect(adoc_text).to include('////')
      end

      it 'round-trips TOC through CoreModel back to Markdown' do
        toc = Coradoc::Markdown::Extension.toc
        core = Coradoc::Markdown.to_core_model(toc)
        md_ext = Coradoc::Markdown.from_core_model(core)

        expect(md_ext).to be_a(Coradoc::Markdown::Extension)
        expect(md_ext.name.to_sym).to eq(:toc)
      end
    end

    describe 'Markdown AttributeList → CoreModel' do
      it 'transforms AttributeList to CoreModel StructuralElement with attributes' do
        attr_list = Coradoc::Markdown::AttributeList.new(
          id: 'intro',
          classes: %w[highlight important],
          attributes: { 'data-type' => 'example' }
        )
        core = Coradoc::Markdown.to_core_model(attr_list)

        expect(core).to be_a(Coradoc::CoreModel::StructuralElement)
        expect(core.element_type).to eq('attribute_list')
        expect(core.children.length).to eq(4) # 1 id + 2 classes + 1 attribute
      end

      it 'preserves id in AttributeList transformation' do
        attr_list = Coradoc::Markdown::AttributeList.new(id: 'section-1')
        core = Coradoc::Markdown.to_core_model(attr_list)

        id_attr = core.children.find { |c| c.is_a?(Coradoc::CoreModel::ElementAttribute) && c.name == 'id' }
        expect(id_attr).not_to be_nil
        expect(id_attr.value).to eq('section-1')
      end

      it 'preserves classes in AttributeList transformation' do
        attr_list = Coradoc::Markdown::AttributeList.new(classes: %w[note warning])
        core = Coradoc::Markdown.to_core_model(attr_list)

        class_attrs = core.children.select { |c| c.is_a?(Coradoc::CoreModel::ElementAttribute) && c.name == 'class' }
        expect(class_attrs.length).to eq(2)
        expect(class_attrs.map(&:value)).to contain_exactly('note', 'warning')
      end
    end

    describe 'CoreModel → AsciiDoc inline stem serialization' do
      it 'serializes Inline::Stem to latexmath macro' do
        stem = Coradoc::AsciiDoc::Model::Inline::Stem.new(
          type: 'latexmath',
          content: 'E = mc^2'
        )
        expect(stem.to_adoc).to eq('latexmath:[E = mc^2]')
      end

      it 'serializes Inline::Stem with default type' do
        stem = Coradoc::AsciiDoc::Model::Inline::Stem.new(
          content: 'x + y'
        )
        expect(stem.to_adoc).to eq('stem:[x + y]')
      end
    end
  end

  # Missing format pair tests (TODO 04)
  describe 'DOCX → CoreModel → Markdown flow' do
    let(:docx_doc) do
      doc = Uniword::Wordprocessingml::DocumentRoot.new
      doc.body.paragraphs << Uniword::Wordprocessingml::Paragraph.new.tap do |p|
        p.properties = Uniword::Wordprocessingml::ParagraphProperties.new
        p.properties.style = Uniword::Properties::StyleReference.new(value: 'Heading1')
        run = Uniword::Wordprocessingml::Run.new
        run.text = Uniword::Wordprocessingml::Text.new(content: 'Title')
        p.runs << run
      end
      doc.body.paragraphs << Uniword::Wordprocessingml::Paragraph.new.tap do |p|
        run = Uniword::Wordprocessingml::Run.new
        run.text = Uniword::Wordprocessingml::Text.new(content: 'Hello World')
        p.runs << run
      end
      doc
    end

    it 'transforms DOCX to CoreModel to Markdown' do
      skip 'DOCX gem not loaded' unless defined?(Coradoc::Docx)

      core = Coradoc::Docx.parse_to_core(docx_doc)
      expect(core).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(core.element_type).to eq('document')

      md_doc = Coradoc::Markdown.from_core_model(core)
      expect(md_doc).to be_a(Coradoc::Markdown::Document)
      md_text = md_doc.to_md
      expect(md_text).to include('Hello World')
    end
  end

  describe 'DOCX → CoreModel → HTML flow' do
    let(:docx_doc) do
      doc = Uniword::Wordprocessingml::DocumentRoot.new
      doc.body.paragraphs << Uniword::Wordprocessingml::Paragraph.new.tap do |p|
        run = Uniword::Wordprocessingml::Run.new
        run.text = Uniword::Wordprocessingml::Text.new(content: 'DOCX paragraph')
        p.runs << run
      end
      doc
    end

    it 'transforms DOCX to CoreModel to HTML' do
      skip 'DOCX gem not loaded' unless defined?(Coradoc::Docx)

      core = Coradoc::Docx.parse_to_core(docx_doc)
      html = Coradoc::Html.serialize_static(core)

      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('DOCX paragraph')
    end
  end

  describe 'Markdown → CoreModel → DOCX flow' do
    let(:md_content) do
      <<~MD
        # Title

        This is a paragraph.
      MD
    end

    it 'transforms Markdown to CoreModel to DOCX model' do
      skip 'DOCX gem not loaded' unless defined?(Coradoc::Docx)

      md_doc = Coradoc::Markdown.parse(md_content)
      core = Coradoc::Markdown.to_core_model(md_doc)

      expect(core).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(core.element_type).to eq('document')

      docx_model = Coradoc::Docx::Transform::FromCoreModel.transform(core)
      expect(docx_model).not_to be_nil
    end
  end

  describe 'AsciiDoc → CoreModel → DOCX flow' do
    let(:adoc_content) do
      <<~ADOC
        = Document Title

        == Section

        A paragraph with *bold* text.
      ADOC
    end

    it 'transforms AsciiDoc to CoreModel to DOCX model' do
      skip 'AsciiDoc parser required' unless defined?(Coradoc::AsciiDoc::Parser::Base)
      skip 'DOCX gem not loaded' unless defined?(Coradoc::Docx)

      ast = Coradoc::AsciiDoc::Parser::Base.parse(adoc_content)
      adoc_doc = Coradoc::AsciiDoc::Transformer.transform(ast)
      core = Coradoc::AsciiDoc::Transform::ToCoreModel.transform(adoc_doc)

      expect(core).to be_a(Coradoc::CoreModel::StructuralElement)

      docx_model = Coradoc::Docx::Transform::FromCoreModel.transform(core)
      expect(docx_model).not_to be_nil
    end
  end

  describe 'HTML → CoreModel → Markdown flow' do
    let(:html_content) do
      <<~HTML
        <html>
          <body>
            <h1>Title</h1>
            <p>A paragraph.</p>
            <ul>
              <li>Item 1</li>
              <li>Item 2</li>
            </ul>
          </body>
        </html>
      HTML
    end

    it 'transforms HTML to CoreModel to Markdown' do
      html_models = Coradoc::Input::Html.to_coradoc(html_content, {})
      expect(html_models).not_to be_nil

      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Title',
        children: html_models.map { |m| Coradoc::AsciiDoc::Transform::ToCoreModel.transform(m) }.compact
      )

      md_doc = Coradoc::Markdown.from_core_model(core_doc)
      expect(md_doc).to be_a(Coradoc::Markdown::Document)

      md_text = md_doc.to_md
      expect(md_text).to include('A paragraph.')
    end
  end

  describe 'HTML → CoreModel → DOCX flow' do
    let(:html_content) do
      <<~HTML
        <html>
          <body>
            <h1>Title</h1>
            <p>HTML paragraph.</p>
          </body>
        </html>
      HTML
    end

    it 'transforms HTML to CoreModel to DOCX model' do
      skip 'DOCX gem not loaded' unless defined?(Coradoc::Docx)

      html_models = Coradoc::Input::Html.to_coradoc(html_content, {})
      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Title',
        children: html_models.map { |m| Coradoc::AsciiDoc::Transform::ToCoreModel.transform(m) }.compact
      )

      docx_model = Coradoc::Docx::Transform::FromCoreModel.transform(core_doc)
      expect(docx_model).not_to be_nil
    end
  end
end
