require "spec_helper"

RSpec.describe Coradoc::Transformer do
  describe ".transform" do
    it "transform the abstract syntax tree to base document" do
      sample_file = Coradoc.root_path.join("spec", "fixtures", "sample.adoc")
      syntax_tree = Coradoc::Parser.parse(sample_file)

      transformed = Coradoc::Transformer.transform(syntax_tree)
      transformed_doc = transformed[:document]

      expect_it_to_extract_document_header(transformed_doc[0])

      expect_it_to_extract_section_with_title(transformed_doc[15])
      expect_it_to_extract_basic_block_from_ast(transformed_doc[16])
      expect_it_to_extract_caption_title_from_ast(transformed_doc[17])
      expect_it_to_extract_title_with_block_from_ast(transformed_doc[18])
      expect_it_to_extract_block_from_ast(transformed_doc[19], :example)
      expect_it_to_extract_block_from_ast(transformed_doc[20], :source)
      expect_it_to_extract_block_from_ast(transformed_doc[21], :source)
      expect_it_to_extract_block_from_ast(transformed_doc[22], :side)
      expect_it_to_extract_block_from_ast(transformed_doc[23], :side)
      expect_it_to_extract_block_from_ast(transformed_doc[24], :quote)
      expect_it_to_extract_block_from_ast(transformed_doc[25], :quote)
      expect_it_to_extract_admonition_type_ast(transformed_doc[26])
      expect_it_to_extract_empty_section_ast(transformed_doc[27])
      expect_it_to_extract_anchor_section_ast(transformed_doc[28])
      expect_it_to_extract_link_section_ast(transformed_doc[29])
    end
  end

  def expect_it_to_extract_document_header(doc)
    header = doc[:header]

    expect(header.title).to eq("This is the title")
    expect(header.class).to eq(Coradoc::Document::Header)
    expect(header.author.class).to eq(Coradoc::Document::Author)
    expect(header.revision.class).to eq(Coradoc::Document::Revision)
  end

  def expect_it_to_extract_section_with_title(doc)
    section = doc[:section]

    expect(section.class).to eq(Coradoc::Document::Section)
    expect(section.title.class).to eq(Coradoc::Document::Title)
  end

  def expect_it_to_extract_basic_block_from_ast(doc)
    section = doc[:section]

    expect(section.title.class).to eq(Coradoc::Document::Title)
    expect(section.blocks.first.class).to eq(Coradoc::Document::Block)
    expect(section.blocks.first.attributes.class).to eq(Coradoc::Document::Attribute)
  end

  def expect_it_to_extract_caption_title_from_ast(doc)
    block = doc[:block]

    expect(block.type).to be_nil
    expect(block.title).to eq("Caption title")
    expect(block.lines.first.class).to eq(Coradoc::Document::TextElement)
  end

  def expect_it_to_extract_title_with_block_from_ast(doc)
    section = doc[:section]

    expect(section.blocks.first.type).to eq(:example)
    expect(section.title.class).to eq(Coradoc::Document::Title)
    expect(section.blocks.first.class).to eq(Coradoc::Document::Block)
  end

  def expect_it_to_extract_block_from_ast(doc, type)
    block = doc[:block]

    expect(block.type).to eq(type)
    expect(block.lines).not_to be_nil
    expect(block.class).to eq(Coradoc::Document::Block)
  end

  def expect_it_to_extract_admonition_type_ast(transformed_doc)
    section = transformed_doc[:section]

    expect(section.paragraphs.count).to eq(10)
    expect(section.paragraphs[1].type).to eq(:note)
    expect(section.paragraphs[1].content).to eq("This is a note.")

    expect(section.title.class).to eq(Coradoc::Document::Title)
    expect(section.paragraphs[1].class).to eq(Coradoc::Document::Admonition)
    expect(section.paragraphs[9].class).to eq(Coradoc::Document::Admonition)
    expect(section.paragraphs.first.class).to eq(Coradoc::Document::TextElement)
  end

  def expect_it_to_extract_empty_section_ast(transformed_doc)
    section = transformed_doc[:section]

    expect(section.paragraphs).to be_empty
    expect(section.class).to eq(Coradoc::Document::Section)
    expect(section.title.class).to eq(Coradoc::Document::Title)
  end

  def expect_it_to_extract_anchor_section_ast(transformed_doc)
    section = transformed_doc[:section]

    expect(section.paragraphs.count).to eq(3)
    expect(section.title.level).to eq(:heading_three)
    expect(section.title.id).to eq("this-is-an-anchor")
    expect(section.class).to eq(Coradoc::Document::Section)
    expect(section.title.class).to eq(Coradoc::Document::Title)
  end

  def expect_it_to_extract_link_section_ast(transformed_doc)
    section = transformed_doc[:section]

    expect(section.paragraphs.count).to eq(2)
    expect(section.title.content).to eq("Links")
    expect(section.paragraphs.first.content).to eq(
      "This renders as a URL: https://www.example.com."
    )

    expect(section.class).to eq(Coradoc::Document::Section)
    expect(section.title.class).to eq(Coradoc::Document::Title)
  end
end

